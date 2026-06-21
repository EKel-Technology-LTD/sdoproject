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
    return new Opportunity(
      Name = 'Industry Default Test',
      AccountId = accountId,
      CloseDate = Date.today().addDays(30),
      StageName = 'Prospecting'
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
