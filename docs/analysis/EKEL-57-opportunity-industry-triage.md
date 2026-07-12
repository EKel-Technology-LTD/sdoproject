# EKEL-57 — Opportunity Customer Industry Triage

Source: https://linear.app/ekeltechnology/issue/EKEL-57/在每筆銷售商機中記錄客戶所屬產業

## Verdict

Ready for technical design, but not ready for build until the industry taxonomy, source of truth, requiredness timing, and backfill/reporting expectations are confirmed.

## Requirement Summary

The business wants each Opportunity to capture the customer's industry in a consistent selectable way so sales managers can analyze pipeline and closed revenue by industry, while sales users can fill the value easily and avoid data-entry mistakes.

## Gaps and Ambiguities

1. Industry source of truth is undefined.
   - Salesforce already has a standard `Account.Industry` picklist.
   - The story says record industry on every Opportunity, but does not say whether this should be inherited from Account, manually selected on Opportunity, or snapshotted from Account at creation time.

2. Reporting behavior over time is unclear.
   - If reports use `Opportunity.Account.Industry`, historical closed revenue changes when the Account industry changes later.
   - If Opportunity stores its own picklist value, it can preserve historical context, but it can drift from the Account unless sync rules are defined.

3. Industry value taxonomy is missing.
   - No approved picklist values are provided.
   - Need confirmation whether to use Salesforce standard Industry values, a company-specific list, translated Traditional Chinese labels, or a global value set shared with Account.

4. Requiredness rules are unspecified.
   - Should the field be required for all Opportunities, only new Opportunities, only before a specific Stage, or only before Closed Won / Closed Lost?
   - Making it required at field level could block integrations, imports, lead conversion, and legacy data updates.

5. Backfill expectations are missing.
   - Existing Opportunities may not have the new value.
   - Need criteria for backfill from related Account, owner review, default value, or leaving blank until updated.

6. Accountless or special-case Opportunities are not addressed.
   - Some orgs may allow Opportunities without Account, use Person Accounts, partner/channel selling, or parent/child account structures.
   - Need rule for which account's industry should drive the value.

7. Page layout and user experience are not specified.
   - Need placement on Opportunity page layout / Lightning record page.
   - Need whether sales users can edit the value or whether it should be read-only after sync.

8. Security and visibility are not specified.
   - Need field-level security for sales reps, sales managers, admins, integrations, and reporting users.
   - Need whether the field is visible/editable in API and data loads.

9. Reporting deliverables are undefined.
   - The outcome mentions management analysis, but no report/dashboard acceptance criteria are listed.
   - Need whether this story includes report type/report/dashboard changes or only metadata enabling future reports.

10. Lead conversion behavior is not addressed.
    - If industry is captured on Lead and converted to Account/Opportunity, mapping behavior should be defined.

## Missing Acceptance Criteria

Recommended acceptance criteria before implementation:

1. Opportunity has a selectable Industry field with an approved controlled picklist / global value set.
2. The field appears on the intended Opportunity page layout(s) and Lightning record page(s).
3. Sales users can select only approved values; free text is not allowed.
4. Requiredness is enforced at the agreed lifecycle point, e.g. before moving to Proposal or before Closed Won.
5. Existing Opportunities are handled by an agreed backfill rule.
6. If an Opportunity has an Account with `Account.Industry`, the default/sync behavior is explicitly defined.
7. Sales managers can group pipeline amount and closed-won amount by Opportunity Industry in reports.
8. Field-level security is granted to the correct profiles/permission sets.
9. API/import behavior is documented so integrations are not unexpectedly blocked.

## Initial Technical Design

### Recommended Approach

Use a custom picklist field on Opportunity, for example `Customer_Industry__c`, backed by a shared/global value set if the org wants the same values on Account and Opportunity.

Prefer this over reporting directly on `Account.Industry` because the requirement says every Opportunity should record industry, and management revenue analysis usually needs a stable historical snapshot for closed Opportunities.

### Source-of-Truth Options

Option A — Opportunity snapshot field, recommended:

- Add `Opportunity.Customer_Industry__c` as a controlled picklist.
- On Opportunity create and when `AccountId` changes, default from related `Account.Industry` when present.
- Allow sales users to override if the Opportunity's buying context differs from the Account's primary industry.
- Preserve closed Opportunity values unless a business-approved correction is made.

Option B — Formula/report via Account.Industry:

- Lowest implementation effort.
- No duplicate data.
- Risk: historical revenue/pipeline reports shift when Account industry changes; does not satisfy “record in each Opportunity” as strongly.

Option C — Strict Account source of truth:

- Maintain `Account.Industry` only and make Opportunity field read-only/synced.
- Good consistency, but weaker flexibility for multi-industry customers or opportunity-specific business units.

### Affected Salesforce Components

Likely metadata components:

- `Opportunity.Customer_Industry__c` custom picklist field.
- Optional GlobalValueSet, e.g. `Customer_Industry` or reuse an existing Industry value set if available.
- Opportunity page layouts / Lightning record page placement.
- Permission set(s) or profile field-level security.
- Validation Rule or Record-Triggered Flow for lifecycle requiredness.
- Before-save Record-Triggered Flow to default from Account industry on create / Account change, if chosen.
- Reports or report folder/dashboard updates if included in scope.
- Optional data migration/backfill script using SOQL/Data Loader/SF CLI.

### Capability Library / Salesforce Skills Usage

The project is a Salesforce DX project using API version 66.0 with a single package directory `force-app`. The design should be delivered as source-format metadata under `force-app/main/default` and validated with Salesforce CLI deploy/validate commands.

For implementation, use the project's Salesforce capability set:

- SFDX source metadata for custom fields, global value sets, layouts, flows, validation rules, and permission sets.
- Salesforce CLI for deploy validation and org checks.
- SOQL to inspect existing Account/Opportunity industry data before defining migration rules.
- Report/dashboard metadata only if reporting output is included in acceptance criteria.

### Data Migration / Backfill Design

If historical Opportunities must be reportable immediately:

1. Query Opportunities with Account industry available.
2. Backfill `Customer_Industry__c` from `Opportunity.Account.Industry` for open Opportunities and optionally closed Opportunities.
3. Produce an exception list for Opportunities without Account or Account Industry.
4. Ask sales owners/admins to resolve exceptions.

### Risks

1. Picklist taxonomy misalignment can make future reports inconsistent.
2. Field-level requiredness can break integrations, imports, lead conversion, or automated Opportunity creation.
3. Account industry changes can either unintentionally rewrite history or cause drift, depending on sync design.
4. Existing data quality on Account.Industry may be poor, making auto-backfill unreliable.
5. Multiple record types/business units may require different visible values or requiredness timing.
6. Report users may expect dashboards, not just a field; scope creep is likely unless reporting deliverables are explicit.

## Effort Estimate

Simple, assuming taxonomy and requiredness are confirmed:

- Metadata-only field + page/FLS: 0.5 day.
- Add defaulting flow + validation rule + deploy validation: 0.5–1 day.
- Backfill analysis/import and report/dashboard updates: add 0.5–1.5 days depending on data quality and scope.

## Recommendation

Approve design after confirming four decisions:

1. Use Opportunity snapshot field or Account.Industry reporting?
2. What exact industry values and translations should be used?
3. When must sales users fill the field?
4. Should existing Opportunities be backfilled, and from what source?
