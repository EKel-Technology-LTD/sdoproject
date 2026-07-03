public with sharing class SDO_ServiceLeadDispatchProbe {
  @TestVisible
  private static Integer dispatchAttemptCount = 0;
  @TestVisible
  private static Set<Id> contextRecordIds = new Set<Id>();
  @TestVisible
  private static Set<String> recipientPhones = new Set<String>();

  public class DispatchRequest {
    @InvocableVariable(label='Context Record Id')
    public Id contextRecordId;

    @InvocableVariable(label='Recipient Phone')
    public String recipientPhone;
  }

  @InvocableMethod(label='Record SDO Service Dispatch Attempt')
  public static void recordDispatchAttempts(List<DispatchRequest> requests) {
    if (!Test.isRunningTest() || requests == null) {
      return;
    }

    for (DispatchRequest request : requests) {
      dispatchAttemptCount++;
      if (request == null) {
        continue;
      }
      if (request.contextRecordId != null) {
        contextRecordIds.add(request.contextRecordId);
      }
      if (String.isNotBlank(request.recipientPhone)) {
        recipientPhones.add(request.recipientPhone);
      }
    }
  }

  @TestVisible
  private static void reset() {
    dispatchAttemptCount = 0;
    contextRecordIds.clear();
    recipientPhones.clear();
  }
}
