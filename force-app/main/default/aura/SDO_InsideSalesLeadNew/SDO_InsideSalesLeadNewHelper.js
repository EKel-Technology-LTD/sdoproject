/* eslint-disable no-unused-expressions */
({
  routeUser: function (component) {
    var action = component.get("c.canUseInsideSalesLeadCreate");
    action.setCallback(this, function (response) {
      if (
        response.getState() === "SUCCESS" &&
        response.getReturnValue() === true
      ) {
        component.set("v.flowStartError", null);
        component.set("v.flowStartAttempts", 0);
        component.set("v.checkedAccess", true);
        this.startInsideSalesFlow(component);
        return;
      }
      this.navigateToStandardNewLead();
    });
    $A.enqueueAction(action);
  },

  startInsideSalesFlow: function (component) {
    var helper = this;
    var flow;
    var attempts;

    if (component.get("v.flowStarted")) {
      return;
    }

    flow = component.find("insideSalesLeadFlow");
    if (flow && typeof flow.startFlow === "function") {
      component.set("v.flowStarted", true);
      flow.startFlow("SDO_Inside_Sales_Create_Lead");
      return;
    }

    attempts = component.get("v.flowStartAttempts") || 0;
    if (attempts < 5) {
      component.set("v.flowStartAttempts", attempts + 1);
      window.setTimeout(
        $A.getCallback(function () {
          if (component.isValid()) {
            helper.startInsideSalesFlow(component);
          }
        }),
        100
      );
      return;
    }

    component.set(
      "v.flowStartError",
      "The Inside Sales Lead flow could not be started. Refresh the page and try again, or contact your Salesforce administrator."
    );
  },

  navigateToStandardNewLead: function () {
    var navigate = $A.get("e.force:navigateToURL");
    if (navigate) {
      navigate.setParams({ url: "/lightning/o/Lead/new?nooverride=1" });
      navigate.fire();
    } else {
      window.location.assign("/lightning/o/Lead/new?nooverride=1");
    }
  },

  navigateToLeadList: function () {
    var navigate = $A.get("e.force:navigateToURL");
    if (navigate) {
      navigate.setParams({ url: "/lightning/o/Lead/list?filterName=Recent" });
      navigate.fire();
    } else {
      window.location.assign("/lightning/o/Lead/list?filterName=Recent");
    }
  }
});
