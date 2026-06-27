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
    Opportunity opp = baseOpportunity(
      'Current quarter required',
      outsideCurrentQuarter(),
      100
    );
    opp.StageName = WON_STAGE;

    Database.SaveResult result = Database.insert(opp, false);

    System.assertEquals(
      false,
      result.isSuccess(),
      'Won Opportunity outside the current quarter should be blocked.'
    );
    assertErrorContains(result, '本季');
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
    Account account = new Account(Name = 'SDO Validation Test Account');
    insert account;

    PricebookEntry entry = createPricebookEntry();
    Opportunity opp = new Opportunity(
      Name = 'Complete won Opportunity',
      AccountId = account.Id,
      StageName = OPEN_STAGE,
      CloseDate = Date.today(),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert opp;

    insert new OpportunityLineItem(
      OpportunityId = opp.Id,
      PricebookEntryId = entry.Id,
      Quantity = 1,
      UnitPrice = 100
    );

    opp.StageName = WON_STAGE;
    Database.SaveResult result = Database.update(opp, false);

    System.assertEquals(true, result.isSuccess(), firstError(result));
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

    System.assertEquals(true, result.isSuccess(), firstError(result));
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
      firstError(result).contains(expectedText),
      'Expected error to contain "' +
        expectedText +
        '" but got: ' +
        firstError(result)
    );
  }

  private static String firstError(Database.SaveResult result) {
    if (result.getErrors().isEmpty()) {
      return '';
    }
    return result.getErrors()[0].getMessage();
  }
}
