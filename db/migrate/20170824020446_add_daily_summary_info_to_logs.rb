class AddDailySummaryInfoToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :info_for_next_day, :text
    add_column :logs, :volunteer_feedback, :text
  end
end
