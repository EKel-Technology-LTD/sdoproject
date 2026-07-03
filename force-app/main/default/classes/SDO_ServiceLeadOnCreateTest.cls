@IsTest
private class SDO_ServiceLeadOnCreateTest {
  private static final String DEFAULT_RECORD_TYPE = 'SDO_Lead_Default';
  private static final String INSIDE_SALES_SOURCE = 'Partner';

  @IsTest
  static void defaultPartnerLeadSkipsServiceAutomation() {
    enableServiceAutomation();
    RecordType defaultRecordType = getDefaultLeadRecordType();
    String openDefaultStatus = getOpenDefaultStatus();

    Test.startTest();
    Lead insideSalesLead = buildDefaultPartnerLead(
      'Inside Sales Partner',
      'EKel Test Company',
      '4155550100',
      defaultRecordType.Id,
      openDefaultStatus
    );
    insert insideSalesLead;
    Test.stopTest();

    Lead savedLead = [
      SELECT Id, LeadSource, RecordType.DeveloperName, Phone
      FROM Lead
      WHERE Id = :insideSalesLead.Id
    ];
    System.assertEquals(
      INSIDE_SALES_SOURCE,
      savedLead.LeadSource,
      'The inside-sales Partner lead should be created.'
    );
    System.assertEquals(
      DEFAULT_RECORD_TYPE,
      savedLead.RecordType.DeveloperName,
      'The test must exercise the SDO default Lead record type used by the routing skip condition.'
    );
    System.assertEquals(
      '4155550100',
      savedLead.Phone,
      'A phone number is present so non-skipped service automation would have enough input to continue.'
    );
    assertNoSmsDispatchArtifacts(new Set<String>{ savedLead.Phone });
  }

  @IsTest
  static void bulkDefaultPartnerLeadsSkipServiceAutomation() {
    enableServiceAutomation();
    RecordType defaultRecordType = getDefaultLeadRecordType();
    String openDefaultStatus = getOpenDefaultStatus();
    List<Lead> leadsToInsert = new List<Lead>();

    for (Integer i = 0; i < 200; i++) {
      leadsToInsert.add(
        buildDefaultPartnerLead(
          'Bulk Partner ' + i,
          'EKel Bulk Company ' + i,
          '415555' + String.valueOf(1000 + i),
          defaultRecordType.Id,
          openDefaultStatus
        )
      );
    }

    Test.startTest();
    insert leadsToInsert;
    Test.stopTest();

    Set<Id> leadIds = new Map<Id, Lead>(leadsToInsert).keySet();
    Integer insertedCount = [
      SELECT COUNT()
      FROM Lead
      WHERE Id IN :leadIds
    ];
    System.assertEquals(
      200,
      insertedCount,
      'The skip branch must support bulk Lead imports for all default Partner Leads.'
    );
    Set<String> phoneNumbers = new Set<String>();
    for (Lead insertedLead : leadsToInsert) {
      phoneNumbers.add(insertedLead.Phone);
    }
    assertNoSmsDispatchArtifacts(phoneNumbers);
  }

  private static RecordType getDefaultLeadRecordType() {
    return [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Lead' AND DeveloperName = :DEFAULT_RECORD_TYPE
      LIMIT 1
    ];
  }

  private static String getOpenDefaultStatus() {
    return [
      SELECT MasterLabel
      FROM LeadStatus
      WHERE IsDefault = TRUE AND IsConverted = FALSE
      LIMIT 1
    ]
    .MasterLabel;
  }

  private static Lead buildDefaultPartnerLead(
    String lastName,
    String company,
    String phone,
    Id recordTypeId,
    String status
  ) {
    return new Lead(
      LastName = lastName,
      Company = company,
      LeadSource = INSIDE_SALES_SOURCE,
      Phone = phone,
      RecordTypeId = recordTypeId,
      Status = status
    );
  }

  private static void enableServiceAutomation() {
    xDO_Tool_ProcessAutomationSwitch__c automationSwitch = xDO_Tool_ProcessAutomationSwitch__c.getOrgDefaults();
    automationSwitch.xDO_Tool_ProcessAutomation__c = true;
    if (automationSwitch.Id == null) {
      automationSwitch.SetupOwnerId = UserInfo.getOrganizationId();
    }
    upsert automationSwitch;
  }

  private static void assertNoSmsDispatchArtifacts(Set<String> phoneNumbers) {
    Schema.SObjectType messagingEndUserType = Schema.getGlobalDescribe()
      .get('MessagingEndUser');
    System.assertNotEquals(
      null,
      messagingEndUserType,
      'The SDO SMS service automation path must be observable through MessagingEndUser records.'
    );
    System.assert(
      messagingEndUserType.getDescribe()
        .fields.getMap()
        .containsKey('MessagingPlatformKey'),
      'MessagingEndUser.MessagingPlatformKey must be queryable to verify SMS dispatch artifacts.'
    );

    Integer messagingEndUsers = Database.countQuery(
      'SELECT COUNT() FROM MessagingEndUser WHERE MessagingPlatformKey IN :phoneNumbers'
    );
    System.assertEquals(
      0,
      messagingEndUsers,
      'Default Partner Leads should skip the SMS service automation path and must not create SMS MessagingEndUser artifacts for their phone numbers.'
    );
  }
}
