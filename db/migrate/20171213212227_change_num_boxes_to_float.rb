class ChangeNumBoxesToFloat < ActiveRecord::Migration
  def change
    change_column :log_parts, :num_boxes, :float
  end
end
