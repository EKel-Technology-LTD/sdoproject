public without sharing class OpportunityIndustryDefaultingHandler {
  public static void beforeSave(List<Opportunity> opportunities) {
    Set<Id> accountIds = new Set<Id>();
    for (Opportunity opportunity : opportunities) {
      if (
        opportunity.AccountId != null &&
        String.isBlank(opportunity.SDO_Sales_Industry__c)
      ) {
        accountIds.add(opportunity.AccountId);
      }
    }

    if (accountIds.isEmpty()) {
      return;
    }

    Map<Id, Account> accountsById = new Map<Id, Account>(
      [
        SELECT Industry
        FROM Account
        WHERE Id IN :accountIds
      ]
    );
    Set<String> supportedOpportunityIndustries = getSupportedOpportunityIndustries();

    for (Opportunity opportunity : opportunities) {
      if (
        opportunity.AccountId == null ||
        !String.isBlank(opportunity.SDO_Sales_Industry__c)
      ) {
        continue;
      }

      Account relatedAccount = accountsById.get(opportunity.AccountId);
      if (relatedAccount == null) {
        continue;
      }

      String resolvedIndustry = resolveIndustryValue(
        relatedAccount.Industry,
        supportedOpportunityIndustries
      );
      if (resolvedIndustry != null) {
        opportunity.SDO_Sales_Industry__c = resolvedIndustry;
      }
    }
  }

  @TestVisible
  private static String resolveIndustryValue(
    String accountIndustry,
    Set<String> supportedOpportunityIndustries
  ) {
    if (String.isBlank(accountIndustry)) {
      return null;
    }

    return supportedOpportunityIndustries.contains(accountIndustry)
      ? accountIndustry
      : null;
  }

  private static Set<String> getSupportedOpportunityIndustries() {
    Set<String> supportedValues = new Set<String>();
    for (
      Schema.PicklistEntry entry : Opportunity.SDO_Sales_Industry__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive()) {
        supportedValues.add(entry.getValue());
      }
    }
    return supportedValues;
  }
}
