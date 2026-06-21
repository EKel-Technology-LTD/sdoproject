({
    doInit: function (component) {
        if ($A.get("$Permission.Use_Inside_Sales_Lead_Create")) {
            const flow = component.find("flowData");
            flow.startFlow("SDO_Inside_Sales_Create_Lead");
        } else {
            const navService = component.find("navService");
            navService.navigate({
                type: "standard__webPage",
                attributes: {
                    url: "/lightning/o/Lead/new?nooverride=1"
                }
            });
        }
    },

    handleStatusChange: function (component, event) {
        if (event.getParam("status") !== "FINISHED") {
            return;
        }

        const outputVariables = event.getParam("outputVariables") || [];
        const createdLead = outputVariables.find(function (item) {
            return item.name === "CreatedLeadId";
        });

        if (createdLead && createdLead.value) {
            component.find("navService").navigate({
                type: "standard__recordPage",
                attributes: {
                    recordId: createdLead.value,
                    objectApiName: "Lead",
                    actionName: "view"
                }
            });
        }
    }
});