class LogPart < ActiveRecord::Base
  belongs_to :log
  belongs_to :food_type
  attr_accessible :required, :weight, :count, :description, :food_type_id, :log_id, :num_boxes
  default_scope { order(created_at: :asc) }
  validates :food_type_id, presence: true
  validates :num_boxes, presence: true

  # weight in db is always lbs, so convert to what the user expects to see (in the units of the scale)
  def scale_weight
    display_unit = self.log.scale_type.weight_unit
    if display_unit == "kg"
      self.weight*2.2
    elsif display_unit == "st"
      self.weight*14
    elsif display_unit == "box"
      self.weight*8
    else
      self.weight
    end
  end

end
