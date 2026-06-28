@IsTest
private class OpportunityCloseWonValidationTest {
  private static final String WON_STAGE = 'Closed Won';
  private static final String OPEN_STAGE = 'Qualification';

  @IsTest
  static void wonOpportunityWithoutAmountIsBlocked() {
    Opportunity opp = baseOpportunity('Amount required', Date.today(), null);
    opp.StageName = WON_STAGE;

    Database.SaveResult result = Database.insert(opp, false);

    System.assertEquals(
      false,
      result.isSuccess(),
      'Won Opportunity without Amount should be blocked.'
    );
    assertErrorContains(result, '成交金額');
  }

  @IsTest
  static void wonOpportunityOutsideCurrentQuarterIsBlocked() {
    Opportunity opp = insertOpenOpportunityWithProduct(
      'Current quarter required',
      outsideCurrentQuarter(),
      100
    );
    opp.StageName = WON_STAGE;

    Database.SaveResult result = Database.update(opp, false);

    System.assertEquals(
      false,
      result.isSuccess(),
      'Won Opportunity outside the current quarter should be blocked.'
    );
    assertErrorContains(result, '本季');
  }

  @IsTest
  static void historicalWonOpportunityAllowsNonCloseEdit() {
    Opportunity opp = insertOpenOpportunityWithProduct(
      'Historical won Opportunity',
      Date.today(),
      100
    );
    opp.StageName = WON_STAGE;
    update opp;

    opp.CloseDate = outsideCurrentQuarter();
    update opp;

    opp.Description = 'Historical maintenance update';
    Database.SaveResult result = Database.update(opp, false);

    System.assertEquals(
      true,
      result.isSuccess(),
      'Historical Closed Won maintenance updates should not be blocked by current-quarter validation. ' +
      allErrors(result)
    );
  }

  @IsTest
  static void wonOpportunityWithoutProductIsBlocked() {
    Opportunity opp = baseOpportunity('Product required', Date.today(), 100);
    opp.StageName = WON_STAGE;

    Database.SaveResult result = Database.insert(opp, false);

    System.assertEquals(
      false,
      result.isSuccess(),
      'Won Opportunity without products should be blocked.'
    );
    assertErrorContains(result, '產品');
  }

  @IsTest
  static void completeWonOpportunityCanSave() {
    Opportunity opp = insertOpenOpportunityWithProduct(
      'Complete won Opportunity',
      Date.today(),
      100
    );

    opp.StageName = WON_STAGE;
    Database.SaveResult result = Database.update(opp, false);

    System.assertEquals(true, result.isSuccess(), allErrors(result));
  }

  @IsTest
  static void openOpportunityIsNotBlockedByWonValidation() {
    Opportunity opp = baseOpportunity(
      'Open Opportunity allowed',
      Date.today(),
      null
    );
    opp.StageName = OPEN_STAGE;

    Database.SaveResult result = Database.insert(opp, false);

    System.assertEquals(true, result.isSuccess(), allErrors(result));
  }

  private static Opportunity insertOpenOpportunityWithProduct(
    String name,
    Date closeDate,
    Decimal amount
  ) {
    Account account = new Account(Name = name + ' Account');
    insert account;

    Opportunity opp = baseOpportunity(name, closeDate, amount);
    opp.AccountId = account.Id;
    opp.Pricebook2Id = Test.getStandardPricebookId();
    insert opp;

    insert new OpportunityLineItem(
      OpportunityId = opp.Id,
      PricebookEntryId = createPricebookEntry().Id,
      Quantity = 1,
      UnitPrice = amount == null ? 100 : amount
    );

    return opp;
  }

  private static Opportunity baseOpportunity(
    String name,
    Date closeDate,
    Decimal amount
  ) {
    return new Opportunity(
      Name = name,
      StageName = OPEN_STAGE,
      CloseDate = closeDate,
      Amount = amount
    );
  }

  private static Date outsideCurrentQuarter() {
    Date today = Date.today();
    Integer currentQuarterStartMonth = (((today.month() - 1) / 3) * 3) + 1;
    return Date.newInstance(today.year(), currentQuarterStartMonth, 1)
      .addMonths(3);
  }

  private static PricebookEntry createPricebookEntry() {
    Product2 product = new Product2(
      Name = 'SDO Validation Product',
      IsActive = true
    );
    insert product;

    PricebookEntry entry = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = product.Id,
      UnitPrice = 100,
      IsActive = true
    );
    insert entry;
    return entry;
  }

  private static void assertErrorContains(
    Database.SaveResult result,
    String expectedText
  ) {
    System.assert(
      allErrors(result).contains(expectedText),
      'Expected one validation error to contain "' +
        expectedText +
        '" but got: ' +
        allErrors(result)
    );
  }

  private static String allErrors(Database.SaveResult result) {
    List<String> messages = new List<String>();
    for (Database.Error error : result.getErrors()) {
      messages.add(error.getMessage());
    }
    return String.join(messages, ' | ');
  }
}
