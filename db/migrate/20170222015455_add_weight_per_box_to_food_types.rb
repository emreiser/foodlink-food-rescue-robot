class AddWeightPerBoxToFoodTypes < ActiveRecord::Migration
  def change
    add_column :food_types, :weight_per_box, :decimal
  end
end
