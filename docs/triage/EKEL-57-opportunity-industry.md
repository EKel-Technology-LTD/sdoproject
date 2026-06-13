# EKEL-57 Triage: 在每筆銷售商機中記錄客戶所屬產業

Source: https://linear.app/ekeltechnology/issue/EKEL-57/在每筆銷售商機中記錄客戶所屬產業

## Verdict

Needs work before implementation. The business goal is clear and small, but the implementation is not yet fully actionable because the industry taxonomy and source-of-truth behavior are not specified.

## Gaps / Ambiguities

1. Industry taxonomy is missing
   - Need the exact selectable values, labels, and API values.
   - Need to know whether to reuse Salesforce standard Account.Industry values, use a new Global Value Set, or define a customer-specific list.

2. Source of truth is unclear
   - Should industry be maintained on Account and displayed on Opportunity, or selected directly on every Opportunity?
   - If both Account and Opportunity can store industry, mismatch rules are needed.

3. Snapshot versus live Account value is unclear
   - If Account.Industry changes later, should closed/won historical Opportunities keep their original industry or update for reports?

4. Requiredness timing is unclear
   - Should the industry be required at Opportunity creation, before a specific Stage, or only before Closed Won / Closed Lost?
   - Are any record types, integration users, or data migration jobs exempt?

5. Backfill and data quality expectations are missing
   - Existing open and historical Opportunities need a backfill rule.
   - Need a policy for Opportunities without Account or Accounts with blank Industry.

6. Reporting deliverables are not defined
   - Requirement mentions pipeline and revenue analysis, but does not specify whether to create fields only or also reports/dashboards.
   - Need expected report groupings: pipeline amount, closed-won revenue, win rate, period, owner/team, region, etc.

7. UX placement and permissions are not defined
   - Need target page layouts / Lightning record pages and profiles or permission sets.
   - Need whether field history tracking is required.

## Acceptance Criteria Needed

- Given a sales user creates or edits an Opportunity, then the customer industry is visible in a consistent selectable or derived field.
- Given an Opportunity reaches the configured required stage, then it cannot be saved without customer industry.
- Given managers run Opportunity reports, then they can group/filter by customer industry and aggregate Amount / pipeline / closed-won revenue.
- Given existing Opportunities are in scope, then they are backfilled according to an agreed rule.
- Given Account industry changes after an Opportunity is closed, then the system behavior is explicitly defined as either live update or historical snapshot.

## Initial Technical Design

### Preferred approach if Account is the customer source of truth

Use the standard Account Industry field as the master customer-industry value, then expose it on Opportunity for reporting.

Affected Salesforce metadata:
- `Opportunity` custom formula field, e.g. `CustomerIndustry__c`, formula value `Account.Industry`.
- Opportunity page layout / Lightning record page placement.
- Report type/report updates to include and group by Customer Industry.
- Optional validation rule requiring Account.Industry before the configured Opportunity stage.

Pros:
- Avoids duplicate industry data and reduces sales-user input errors.
- Keeps customer industry maintained at the customer/account level.
- Simple metadata-only implementation.

Cons / risk:
- Historical closed Opportunity reporting changes if Account.Industry is edited later.
- Does not satisfy a strict interpretation of “industry selected on each Opportunity” unless the business accepts derived display.

### Alternative approach if each Opportunity needs a historical snapshot

Create an Opportunity picklist field and default it from Account.Industry at creation/update time.

Affected Salesforce metadata:
- Global Value Set or Opportunity picklist field, e.g. `CustomerIndustry__c`.
- Before-save Flow to default `Opportunity.CustomerIndustry__c` from `Opportunity.Account.Industry` when blank.
- Validation Rule to require it at agreed stage.
- Page layout / Lightning record page updates.
- Permission set/profile field-level security.
- Optional data migration/backfill script for existing Opportunities.
- Reports/dashboards grouped by the new field.

Pros:
- Preserves historical reporting if Account industry changes later.
- Satisfies the requirement that every Opportunity carries its own industry value.

Cons / risk:
- Creates duplicate data and requires sync/defaulting rules.
- Needs clear mismatch handling when Account and Opportunity industry differ.

## Effort Estimate

- Metadata-only field + layout + validation + report-field enablement: 0.5–1 day after values and requiredness are confirmed.
- Add Flow defaulting, backfill, and basic manager reports/dashboard: 1–2 days depending on migration scope and report expectations.

## Recommendation

Do not implement yet. First confirm the industry value list, source-of-truth model, historical snapshot behavior, required stage, backfill scope, and whether reports/dashboards are part of this item.

TRIAGE_RESULT: needs-work
