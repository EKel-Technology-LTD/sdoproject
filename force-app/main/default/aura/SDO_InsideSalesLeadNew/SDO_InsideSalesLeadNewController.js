({
    doInit: function (component, event, helper) {
        helper.routeUser(component);
    },

    handleStatusChange: function (component, event, helper) {
        var status = event.getParam('status');
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            helper.navigateToLeadList();
        }
    }
});
