trigger OpportunityIndustryDefaulting on Opportunity(
  before insert,
  before update
) {
  OpportunityIndustryDefaultingHandler.beforeSave(Trigger.new);
}
