@IsTest
private class OpportunityIndustryDefaultingTest {
  private static User createUser(String suffix) {
    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];

    String uniqueName =
      'opp-industry-' +
      suffix +
      '-' +
      System.now().getTime() +
      '@example.com';
    return new User(
      Alias = ('oi' + suffix).left(8),
      Email = uniqueName,
      EmailEncodingKey = 'UTF-8',
      LastName = 'Opportunity Industry ' + suffix,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = standardProfile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueName
    );
  }

  private static Opportunity newOpportunity(Id accountId) {
    return newOpportunity('Industry Default Test', accountId);
  }

  private static Opportunity newOpportunity(String name, Id accountId) {
    return new Opportunity(
      Name = name,
      AccountId = accountId,
      CloseDate = Date.today().addDays(30),
      StageName = 'Prospecting'
    );
  }

  private static void assignSalesBaseAccess(User salesUser) {
    PermissionSet salesBaseAccess = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'SDO_Sales_Base_Access'
      LIMIT 1
    ];
    insert new PermissionSetAssignment(
      AssigneeId = salesUser.Id,
      PermissionSetId = salesBaseAccess.Id
    );
  }

  @IsTest
  static void copiesAccountIndustryOnCreate() {
    Account accountWithIndustry = new Account(
      Name = 'Technology Account',
      Industry = 'Technology'
    );
    insert accountWithIndustry;

    Opportunity opportunity = newOpportunity(accountWithIndustry.Id);
    insert opportunity;

    Opportunity insertedOpportunity = [
      SELECT SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    System.assertEquals(
      'Technology',
      insertedOpportunity.SDO_Sales_Industry__c,
      'Before-save Flow should copy Account.Industry when the Opportunity industry is blank.'
    );
  }

  @IsTest
  static void copiesFinanceAndHealthcareValuesFromAccountIndustry() {
    List<Account> accounts = new List<Account>{
      new Account(Name = 'Finance Account', Industry = 'Financial Services'),
      new Account(
        Name = 'Healthcare Account',
        Industry = 'Healthcare & Life Sciences'
      )
    };
    insert accounts;

    List<Opportunity> opportunities = new List<Opportunity>{
      newOpportunity('Finance Opportunity', accounts[0].Id),
      newOpportunity('Healthcare Opportunity', accounts[1].Id)
    };
    insert opportunities;

    Map<String, Opportunity> opportunitiesByName = new Map<String, Opportunity>();
    for (Opportunity opportunity : [
      SELECT Name, SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id IN :opportunities
    ]) {
      opportunitiesByName.put(opportunity.Name, opportunity);
    }

    System.assertEquals(
      'Financial Services',
      opportunitiesByName.get('Finance Opportunity').SDO_Sales_Industry__c,
      'Finance must match the Account.Industry API value.'
    );
    System.assertEquals(
      'Healthcare & Life Sciences',
      opportunitiesByName.get('Healthcare Opportunity').SDO_Sales_Industry__c,
      'Healthcare must match the Account.Industry API value.'
    );
  }

  @IsTest
  static void bulkCreatesTwoHundredOpportunitiesWithAccountIndustryDefaults() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      accounts.add(
        new Account(
          Name = 'Bulk Create Account ' + i,
          Industry = Math.mod(i, 2) == 0
            ? 'Financial Services'
            : 'Healthcare & Life Sciences'
        )
      );
    }
    insert accounts;

    List<Opportunity> opportunities = new List<Opportunity>();
    for (Integer i = 0; i < accounts.size(); i++) {
      opportunities.add(
        newOpportunity('Bulk Create Opportunity ' + i, accounts[i].Id)
      );
    }

    Test.startTest();
    insert opportunities;
    Test.stopTest();

    Map<String, Opportunity> opportunitiesByName = new Map<String, Opportunity>();
    for (Opportunity opportunity : [
      SELECT Name, SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id IN :opportunities
    ]) {
      opportunitiesByName.put(opportunity.Name, opportunity);
    }

    for (Integer i = 0; i < opportunities.size(); i++) {
      System.assertEquals(
        Math.mod(i, 2) == 0
          ? 'Financial Services'
          : 'Healthcare & Life Sciences',
        opportunitiesByName.get('Bulk Create Opportunity ' + i)
          .SDO_Sales_Industry__c,
        'Bulk create should default industry for row ' +
          i +
          ' without governor-limit failures.'
      );
    }
  }

  @IsTest
  static void bulkUpdatesTwoHundredOpportunitiesWithAccountIndustryDefaults() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      accounts.add(
        new Account(
          Name = 'Bulk Update Account ' + i,
          Industry = Math.mod(i, 2) == 0
            ? 'Financial Services'
            : 'Healthcare & Life Sciences'
        )
      );
    }
    insert accounts;

    List<Opportunity> opportunities = new List<Opportunity>();
    for (Integer i = 0; i < accounts.size(); i++) {
      opportunities.add(newOpportunity('Bulk Update Opportunity ' + i, null));
    }
    insert opportunities;

    for (Integer i = 0; i < opportunities.size(); i++) {
      opportunities[i].AccountId = accounts[i].Id;
    }

    Test.startTest();
    update opportunities;
    Test.stopTest();

    Map<String, Opportunity> opportunitiesByName = new Map<String, Opportunity>();
    for (Opportunity opportunity : [
      SELECT Name, SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id IN :opportunities
    ]) {
      opportunitiesByName.put(opportunity.Name, opportunity);
    }

    for (Integer i = 0; i < opportunities.size(); i++) {
      System.assertEquals(
        Math.mod(i, 2) == 0
          ? 'Financial Services'
          : 'Healthcare & Life Sciences',
        opportunitiesByName.get('Bulk Update Opportunity ' + i)
          .SDO_Sales_Industry__c,
        'Bulk update should default industry for row ' +
          i +
          ' without governor-limit failures.'
      );
    }
  }

  @IsTest
  static void updateDefaultsIndustryWhenAccountIsAddedLater() {
    Account financeAccount = new Account(
      Name = 'Finance Update Account',
      Industry = 'Financial Services'
    );
    insert financeAccount;

    Opportunity opportunity = newOpportunity('Add Account Later', null);
    insert opportunity;

    opportunity.AccountId = financeAccount.Id;
    update opportunity;

    Opportunity updatedOpportunity = [
      SELECT SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    System.assertEquals(
      'Financial Services',
      updatedOpportunity.SDO_Sales_Industry__c,
      'CreateAndUpdate Flow should backfill industry when AccountId is added later.'
    );
  }

  @IsTest
  static void updateRedefaultsIndustryWhenUserClearsBlankableField() {
    Account healthcareAccount = new Account(
      Name = 'Healthcare Clear Field Account',
      Industry = 'Healthcare & Life Sciences'
    );
    insert healthcareAccount;

    Opportunity opportunity = newOpportunity(
      'Clear Industry With Account',
      healthcareAccount.Id
    );
    opportunity.SDO_Sales_Industry__c = 'Other';
    insert opportunity;

    opportunity.SDO_Sales_Industry__c = null;
    update opportunity;

    Opportunity updatedOpportunity = [
      SELECT SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    System.assertEquals(
      'Healthcare & Life Sciences',
      updatedOpportunity.SDO_Sales_Industry__c,
      'Flow should re-default from Account.Industry when the field is cleared on update.'
    );
  }

  @IsTest
  static void doesNotSilentlyDowngradeUnlistedAccountIndustryToOther() {
    Account accountWithFutureIndustry = new Account(
      Name = 'Future Industry Account',
      Industry = 'Future Industry'
    );
    insert accountWithFutureIndustry;

    Opportunity opportunity = newOpportunity(accountWithFutureIndustry.Id);
    insert opportunity;

    Opportunity insertedOpportunity = [
      SELECT SDO_Sales_Industry__c
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    System.assertEquals(
      'Future Industry',
      insertedOpportunity.SDO_Sales_Industry__c,
      'Unsupported/future Account.Industry values must not be silently changed to Other.'
    );
  }

  @IsTest
  static void salesPersonaMustProvideIndustryWhenNoDefaultExists() {
    User salesUser = createUser('sales');
    insert salesUser;
    assignSalesBaseAccess(salesUser);

    System.runAs(salesUser) {
      Account accountWithoutIndustry = new Account(
        Name = 'No Industry Account'
      );
      insert accountWithoutIndustry;

      try {
        insert newOpportunity(accountWithoutIndustry.Id);
        System.assert(
          false,
          'Sales persona should be blocked when no industry can be defaulted.'
        );
      } catch (DmlException ex) {
        System.assert(
          ex.getMessage().contains('請填寫產業'),
          'Expected the required industry validation message for Sales persona users.'
        );
      }
    }
  }

  @IsTest
  static void salesPersonaCannotClearIndustryOnUpdateWhenNoDefaultExists() {
    User salesUser = createUser('salesupd');
    insert salesUser;
    assignSalesBaseAccess(salesUser);

    System.runAs(salesUser) {
      Opportunity opportunity = newOpportunity(
        'Sales Clear Industry Without Account',
        null
      );
      opportunity.SDO_Sales_Industry__c = 'Other';
      insert opportunity;

      opportunity.SDO_Sales_Industry__c = null;
      try {
        update opportunity;
        System.assert(
          false,
          'Sales persona should be blocked from clearing industry when no Account default exists.'
        );
      } catch (DmlException ex) {
        System.assert(
          ex.getMessage().contains('請填寫產業'),
          'Expected the required industry validation message on update for Sales persona users.'
        );
      }
    }
  }

  @IsTest
  static void salesPersonaCanUpdateUnrelatedFieldsOnExistingBlankIndustry() {
    User salesUser = createUser('salesblank');
    insert salesUser;
    assignSalesBaseAccess(salesUser);

    Opportunity opportunity = newOpportunity('Existing Blank Industry', null);
    opportunity.OwnerId = salesUser.Id;
    insert opportunity;

    System.runAs(salesUser) {
      Opportunity existingBlankOpportunity = [
        SELECT Name, SDO_Sales_Industry__c
        FROM Opportunity
        WHERE Id = :opportunity.Id
      ];
      System.assertEquals(
        null,
        existingBlankOpportunity.SDO_Sales_Industry__c,
        'Test setup should represent existing migrated/imported Opportunities with blank industry.'
      );

      existingBlankOpportunity.Name = 'Existing Blank Industry Renamed';
      update existingBlankOpportunity;
    }
  }

  @IsTest
  static void nonSalesPersonaCanCreateWithoutIndustry() {
    User nonSalesUser = createUser('nonsales');
    insert nonSalesUser;

    System.runAs(nonSalesUser) {
      Account accountWithoutIndustry = new Account(
        Name = 'Non Sales No Industry Account'
      );
      insert accountWithoutIndustry;

      Opportunity opportunity = newOpportunity(accountWithoutIndustry.Id);
      insert opportunity;

      Opportunity insertedOpportunity = [
        SELECT SDO_Sales_Industry__c
        FROM Opportunity
        WHERE Id = :opportunity.Id
      ];
      System.assertEquals(
        null,
        insertedOpportunity.SDO_Sales_Industry__c,
        'Users outside the Sales industry-required persona should not be blocked by the hidden field.'
      );
    }
  }
}
