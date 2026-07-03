@IsTest
private class SDO_ServiceLeadOnCreateTest {
  private static final String DEFAULT_RECORD_TYPE = 'SDO_Lead_Default';
  private static final String INSIDE_SALES_SOURCE = 'Partner';
  private static final String CONTROL_SOURCE = 'Web';

  @IsTest
  static void defaultPartnerLeadSkipsServiceAutomation() {
    enableServiceAutomation();
    RecordType defaultRecordType = getDefaultLeadRecordType();
    String openDefaultStatus = getOpenDefaultStatus();

    Test.startTest();
    SDO_ServiceLeadDispatchProbe.reset();
    Lead insideSalesLead = buildLead(
      'Inside Sales Partner',
      'EKel Test Company',
      INSIDE_SALES_SOURCE,
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
    assertNoServiceDispatchAttempts();
  }

  @IsTest
  static void nonPartnerDefaultLeadReachesServiceDispatchControl() {
    enableServiceAutomation();
    RecordType defaultRecordType = getDefaultLeadRecordType();
    String openDefaultStatus = getOpenDefaultStatus();

    Test.startTest();
    SDO_ServiceLeadDispatchProbe.reset();
    Lead controlLead = buildLead(
      'Service Control',
      'EKel Control Company',
      CONTROL_SOURCE,
      '4155550199',
      defaultRecordType.Id,
      openDefaultStatus
    );
    insert controlLead;
    Test.stopTest();

    assertServiceDispatchAttempts(
      1,
      new Set<Id>{ controlLead.Id },
      new Set<String>{ controlLead.Phone }
    );
  }

  @IsTest
  static void bulkDefaultPartnerLeadsSkipServiceAutomation() {
    enableServiceAutomation();
    RecordType defaultRecordType = getDefaultLeadRecordType();
    String openDefaultStatus = getOpenDefaultStatus();
    List<Lead> leadsToInsert = new List<Lead>();

    for (Integer i = 0; i < 200; i++) {
      leadsToInsert.add(
        buildLead(
          'Bulk Partner ' + i,
          'EKel Bulk Company ' + i,
          INSIDE_SALES_SOURCE,
          '415555' + String.valueOf(1000 + i),
          defaultRecordType.Id,
          openDefaultStatus
        )
      );
    }

    Test.startTest();
    SDO_ServiceLeadDispatchProbe.reset();
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
    assertNoServiceDispatchAttempts();
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

  private static Lead buildLead(
    String lastName,
    String company,
    String leadSource,
    String phone,
    Id recordTypeId,
    String status
  ) {
    return new Lead(
      LastName = lastName,
      Company = company,
      LeadSource = leadSource,
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

  private static void assertNoServiceDispatchAttempts() {
    System.assertEquals(
      0,
      SDO_ServiceLeadDispatchProbe.dispatchAttemptCount,
      'Default Partner Leads must exit through Skip_Inside_Sales_Default_Lead before the SMS/service dispatch point.'
    );
    System.assertEquals(
      0,
      SDO_ServiceLeadDispatchProbe.contextRecordIds.size(),
      'Skipped default Partner Leads must not reach the service dispatch probe.'
    );
    System.assertEquals(
      0,
      SDO_ServiceLeadDispatchProbe.recipientPhones.size(),
      'Skipped default Partner Leads must not provide phone numbers to the SMS/service dispatch path.'
    );
  }

  private static void assertServiceDispatchAttempts(
    Integer expectedAttempts,
    Set<Id> expectedLeadIds,
    Set<String> expectedPhones
  ) {
    System.assertEquals(
      expectedAttempts,
      SDO_ServiceLeadDispatchProbe.dispatchAttemptCount,
      'The positive-control Lead must prove that non-skipped records reach the SMS/service dispatch branch.'
    );
    System.assertEquals(
      expectedLeadIds,
      SDO_ServiceLeadDispatchProbe.contextRecordIds,
      'The dispatch probe should receive the non-skipped Lead Id from the same Flow branch.'
    );
    System.assertEquals(
      expectedPhones,
      SDO_ServiceLeadDispatchProbe.recipientPhones,
      'The dispatch probe should receive the phone number that would be passed to SMS dispatch.'
    );
  }
}
