class RemoveFieldsFromVolunteer < ActiveRecord::Migration
  def up
    remove_column :volunteers, :address
    remove_column :volunteers, :emergency_contact
  end

  def down
    add_column :volunteers, :emergency_contact, :text
    add_column :volunteers, :address, :text
  end
end
