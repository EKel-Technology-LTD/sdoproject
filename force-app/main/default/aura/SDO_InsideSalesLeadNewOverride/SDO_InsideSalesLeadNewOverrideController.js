({
    doInit: function (component) {
        var canUseInsideSalesCreate = $A.get("$Permission.CustomPermission.Use_Inside_Sales_Lead_Create");
        if (canUseInsideSalesCreate) {
            component.set("v.showFlow", true);
            var flow = component.find("leadCreateFlow");
            flow.startFlow("SDO_Inside_Sales_Create_Lead");
        } else {
            window.location.replace("/lightning/o/Lead/new?nooverride=1");
        }
    },

    handleStatusChange: function (component, event) {
        if (event.getParam("status") === "FINISHED") {
            var navigateEvent = $A.get("e.force:navigateToObjectHome");
            if (navigateEvent) {
                navigateEvent.setParams({ scope: "Lead" });
                navigateEvent.fire();
            } else {
                window.location.replace("/lightning/o/Lead/list?filterName=Recent");
            }
        }
    }
});
