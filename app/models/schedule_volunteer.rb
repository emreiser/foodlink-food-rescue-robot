class ScheduleVolunteer < ActiveRecord::Base
	
	belongs_to :schedule_chain
  belongs_to :volunteer

  serialize :week_assignment, Array
  
  attr_accessible :schedule_chain_id, :volunteer_id, :active, :lead_volunteer, :week_assignment

	accepts_nested_attributes_for :volunteer

  WEEK_OPTIONS = {
    "1" => "1st week",
    "2" => "2nd week",
    "3" => "3rd week",
    "4" => "4th week",
    "5" => "5th week",
  }

end
