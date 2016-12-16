class AddAddressAndEmergencyContactToVolunteers < ActiveRecord::Migration
  def change
    add_column :volunteers, :address, :text
    add_column :volunteers, :emergency_contact, :text
  end
end
