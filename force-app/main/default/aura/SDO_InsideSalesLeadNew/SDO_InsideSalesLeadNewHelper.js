({
    routeUser: function (component) {
        var action = component.get('c.canUseInsideSalesLeadCreate');
        action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS' && response.getReturnValue() === true) {
                component.set('v.checkedAccess', true);
                var flow = component.find('insideSalesLeadFlow');
                flow.startFlow('SDO_Inside_Sales_Create_Lead');
                return;
            }
            this.navigateToStandardNewLead();
        });
        $A.enqueueAction(action);
    },

    navigateToStandardNewLead: function () {
        var navigate = $A.get('e.force:navigateToURL');
        if (navigate) {
            navigate.setParams({ url: '/lightning/o/Lead/new?nooverride=1' });
            navigate.fire();
        } else {
            window.location.assign('/lightning/o/Lead/new?nooverride=1');
        }
    },

    navigateToLeadList: function () {
        var navigate = $A.get('e.force:navigateToURL');
        if (navigate) {
            navigate.setParams({ url: '/lightning/o/Lead/list?filterName=Recent' });
            navigate.fire();
        }
    }
});
