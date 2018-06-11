class AddOperationsLeadToLogVolunteers < ActiveRecord::Migration
  def change
    add_column :log_volunteers, :operations_lead, :boolean, :default => false
  end
end
