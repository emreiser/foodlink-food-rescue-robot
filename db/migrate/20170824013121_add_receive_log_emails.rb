class AddReceiveLogEmails < ActiveRecord::Migration
  def change
    add_column :regions, :receive_log_emails, :boolean
  end
end
