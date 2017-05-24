class AddWeekAssignmentToScheduleVolunteers < ActiveRecord::Migration
  def change
    add_column :schedule_volunteers, :week_assignment, :text
  end
end
