public with sharing class SDO_LeadCreateAccessCtrl {
    @AuraEnabled(cacheable=true)
    public static Boolean canUseInsideSalesLeadCreate() {
        return FeatureManagement.checkPermission('Use_Inside_Sales_Lead_Create');
    }
}
