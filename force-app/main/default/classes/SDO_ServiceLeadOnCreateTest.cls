@IsTest
private class SDO_ServiceLeadOnCreateTest {
  @IsTest
  static void defaultPartnerLeadSkipsServiceAutomation() {
    RecordType defaultRecordType = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Lead' AND DeveloperName = 'SDO_Lead_Default'
      LIMIT 1
    ];
    LeadStatus openDefaultStatus = [
      SELECT MasterLabel
      FROM LeadStatus
      WHERE IsDefault = TRUE AND IsConverted = FALSE
      LIMIT 1
    ];

    Test.startTest();
    Lead insideSalesLead = new Lead(
      LastName = 'Inside Sales Partner',
      Company = 'EKel Test Company',
      LeadSource = 'Partner',
      Phone = '4155550100',
      RecordTypeId = defaultRecordType.Id,
      Status = openDefaultStatus.MasterLabel
    );
    insert insideSalesLead;
    Test.stopTest();

    Lead savedLead = [
      SELECT Id, LeadSource, RecordType.DeveloperName, Phone
      FROM Lead
      WHERE Id = :insideSalesLead.Id
    ];
    System.assertEquals(
      'Partner',
      savedLead.LeadSource,
      'The inside-sales Partner lead should be created.'
    );
    System.assertEquals(
      'SDO_Lead_Default',
      savedLead.RecordType.DeveloperName,
      'The test must exercise the SDO default Lead record type used by the routing skip condition.'
    );
    System.assertEquals(
      '4155550100',
      savedLead.Phone,
      'A phone number is present so non-skipped service automation would have enough input to continue.'
    );
  }
}
