class AddNumBoxesToLogParts < ActiveRecord::Migration
  def change
    add_column :log_parts, :num_boxes, :integer
  end
end
