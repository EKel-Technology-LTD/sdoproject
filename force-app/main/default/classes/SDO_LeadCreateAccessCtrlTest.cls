@IsTest
private class SDO_LeadCreateAccessCtrlTest {
    @IsTest
    static void returnsFalseWithoutCustomPermission() {
        User u = createUser('noperm');
        System.runAs(u) {
            System.assertEquals(false, SDO_LeadCreateAccessCtrl.canUseInsideSalesLeadCreate());
        }
    }

    @IsTest
    static void returnsTrueWithInsideSalesPermissionSet() {
        User u = createUser('withperm');
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Inside_Sales_Lead_Create' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        System.runAs(u) {
            System.assertEquals(true, SDO_LeadCreateAccessCtrl.canUseInsideSalesLeadCreate());
        }
    }

    private static User createUser(String key) {
        Profile p = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String unique = key + String.valueOf(System.now().getTime()) + '@example.com';
        User u = new User(
            Alias = key.left(8),
            Email = unique,
            EmailEncodingKey = 'UTF-8',
            LastName = key,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = unique
        );
        insert u;
        return u;
    }
}
