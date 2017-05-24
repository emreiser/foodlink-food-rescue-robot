class ScheduleVolunteer < ActiveRecord::Base
	
	belongs_to :schedule_chain
  belongs_to :volunteer

  serialize :week_assignment, Array
  
  attr_accessible :schedule_chain_id, :volunteer_id, :active, :lead_volunteer, :week_assignment

	accepts_nested_attributes_for :volunteer

  WEEK_OPTIONS = {
    first_third: "1st and 3rd weeks",
    second_fourth: "2nd and 4th weeks",
    fifth: "5th week"
  }

  def get_assigned_weeks
    weeks = []
    weeks.push(1,3) if self.week_assignment.include? "first_third"
    weeks.push(2,4) if self.week_assignment.include? "second_fourth"
    weeks.push(5) if self.week_assignment.include? "fifth"

    weeks
  end

end
