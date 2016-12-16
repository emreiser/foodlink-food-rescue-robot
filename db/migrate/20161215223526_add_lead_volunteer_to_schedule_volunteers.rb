class AddLeadVolunteerToScheduleVolunteers < ActiveRecord::Migration
  def change
    add_column :schedule_volunteers, :lead_volunteer, :boolean, default: false
  end
end
