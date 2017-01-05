class ChangeDefaultOnPreRemindersToo < ActiveRecord::Migration
  def up
    change_column :volunteers, :pre_reminders_too, :boolean, :default => true
  end

  def down
    change_column :volunteers, :pre_reminders_too, :boolean, :default => false
  end
end
