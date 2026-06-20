/* eslint-disable no-unused-expressions */
({
  doInit: function (component) {
    var canUseInsideSalesCreate = $A.get(
      "$Permission.CustomPermission.Use_Inside_Sales_Lead_Create"
    );
    var flow = component.find("leadCreateFlow");

    if (canUseInsideSalesCreate) {
      flow.startFlow("SDO_Inside_Sales_Create_Lead");
    } else {
      window.location.replace("/lightning/o/Lead/new?nooverride=1");
    }
  },

  handleStatusChange: function (component, event) {
    var navigateEvent = $A.get("e.force:navigateToObjectHome");

    if (event.getParam("status") === "FINISHED") {
      if (navigateEvent) {
        navigateEvent.setParams({ scope: "Lead" });
        navigateEvent.fire();
      } else {
        window.location.replace("/lightning/o/Lead/list?filterName=Recent");
      }
    }
  }
});
