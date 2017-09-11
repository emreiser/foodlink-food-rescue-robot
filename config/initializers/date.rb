class Date
  def week_of_month
    # week_of_year(mondays) - beginning_of_month.week_of_year(mondays) + 1
    ((self.day - 1) / 7).floor + 1
  end
end