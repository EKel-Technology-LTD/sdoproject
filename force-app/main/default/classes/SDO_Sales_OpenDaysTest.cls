@IsTest
private class SDO_Sales_OpenDaysTest {
    private static Integer weekdaysBetween(Date startDate, Date endDate) {
        Integer days = 0;
        Date cursor = startDate.addDays(1);
        while (cursor <= endDate) {
            Date weekStart = cursor.toStartOfWeek();
            Integer dayOfWeek = weekStart.daysBetween(cursor) + 1;
            if (dayOfWeek >= 2 && dayOfWeek <= 6) {
                days++;
            }
            cursor = cursor.addDays(1);
        }
        return days;
    }

    private static Opportunity createOpportunity(String name, String stageName, Date closeDate) {
        Account account = new Account(Name = name + ' Account');
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = name,
            AccountId = account.Id,
            StageName = stageName,
            CloseDate = closeDate,
            Amount = 1000
        );
        insert opportunity;
        return opportunity;
    }

    @IsTest
    static void openOpportunityCountsWeekdaysToTodayAndShowsAlert() {
        Date createdDate = Date.today().addDays(-45);
        Opportunity opportunity = createOpportunity('Open Days Open Opportunity', 'Prospecting', Date.today().addDays(30));
        Test.setCreatedDate(opportunity.Id, DateTime.newInstance(createdDate, Time.newInstance(12, 0, 0, 0)));

        Opportunity result = [
            SELECT SDO_Sales_Open_Days__c, SDO_Sales_Open_Days_Alert__c
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];

        System.assertEquals(
            weekdaysBetween(createdDate, Date.today()),
            Integer.valueOf(result.SDO_Sales_Open_Days__c),
            'Open opportunities should count weekdays from CreatedDate through today.'
        );
        System.assertEquals('⚠ 超過 30 工作天', result.SDO_Sales_Open_Days_Alert__c, 'Opportunities open more than 30 weekdays should show the alert.');
    }

    @IsTest
    static void closedOpportunityCountsOnlyThroughCloseDate() {
        Date createdDate = Date.today().addDays(-20);
        Date closeDate = Date.today().addDays(-5);
        Opportunity opportunity = createOpportunity('Open Days Closed Opportunity', 'Closed Lost', closeDate);
        Test.setCreatedDate(opportunity.Id, DateTime.newInstance(createdDate, Time.newInstance(12, 0, 0, 0)));

        Opportunity result = [
            SELECT SDO_Sales_Open_Days__c, SDO_Sales_Open_Days_Alert__c
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];

        System.assertEquals(
            weekdaysBetween(createdDate, closeDate),
            Integer.valueOf(result.SDO_Sales_Open_Days__c),
            'Closed opportunities should stop counting at CloseDate.'
        );
        System.assert(String.isBlank(result.SDO_Sales_Open_Days_Alert__c), 'Alert should be blank at or below the 30 weekday threshold.');
    }

    @IsTest
    static void sameDayOpportunityDisplaysZero() {
        Date createdDate = Date.today();
        Opportunity opportunity = createOpportunity('Open Days Same Day Opportunity', 'Prospecting', Date.today().addDays(10));
        Test.setCreatedDate(opportunity.Id, DateTime.newInstance(createdDate, Time.newInstance(12, 0, 0, 0)));

        Opportunity result = [
            SELECT SDO_Sales_Open_Days__c, SDO_Sales_Open_Days_Alert__c
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];

        System.assertEquals(0, Integer.valueOf(result.SDO_Sales_Open_Days__c), 'Same-day opportunities should show 0 open days.');
        System.assert(String.isBlank(result.SDO_Sales_Open_Days_Alert__c), 'Same-day opportunities should not show an alert.');
    }
}