class AddOperationsLeadToScheduleVolunteers < ActiveRecord::Migration
  def change
    add_column :schedule_volunteers, :operations_lead, :boolean, :default => false
  end
end
