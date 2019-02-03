module ApplicationHelper

  def all_admin_region_volunteer_tuples(whom)
    admin_rids = whom.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    Volunteer.all.collect{ |v|
      v_rids = v.regions.collect{ |r| r.id }
      (admin_rids & v_rids).length > 0 ? [v.name+" ["+v.regions.collect{ |r| r.name }.join(",")+"]",v.id] : nil
    }.compact
  end

  def readable_time_until shift
    ret = shift.when.strftime("%a %b %e") + " ("
    if shift.when == Time.zone.today
      ret += "today"
    elsif shift.when < Time.zone.today
      ret += (Time.zone.today - shift.when).to_i.to_s + " days ago"
    elsif shift.when > Time.zone.today
      ret += (shift.when - Time.zone.today).to_i.to_s + " days from now"
    end
    ret += ")"
    unless shift.schedule_chain.nil?
      ret += " <br>between #{readable_start_time(shift.schedule_chain)} and #{readable_stop_time(shift.schedule_chain)}"
    end
    ret.html_safe
  end

  def readable_start_time schedule
    schedule = schedule.schedule_chain if schedule.is_a? Schedule
    str = 'Unknown'
    str = schedule.detailed_start_time.to_s(:clean_time) if schedule && schedule.detailed_start_time
    str
  end

  def readable_stop_time schedule
    schedule = schedule.schedule_chain if schedule.is_a? Schedule
    str = "Unknown"
    str = schedule.detailed_stop_time.to_s(:clean_time) if schedule && schedule.detailed_stop_time
    str
  end

  def readable_pickup_timespan schedule
    return nil if schedule.nil?
    schedule = schedule.schedule_chain if schedule.is_a? Schedule
    str = "Collection "
    str+= "irregularly " if schedule.irregular
    str+= "every "+Date::DAYNAMES[schedule.day_of_week]+" " if schedule.weekly? and !schedule.day_of_week.nil?
    str+= "on "+schedule.detailed_date.to_s(:long_ordinal)+" " if schedule.one_time?
    str+= "between "
    str+= readable_start_time schedule
    str+= " and "
    str+= readable_stop_time schedule
    str
  end

  def custom_flash(options = {})
    alert_types = [:success, :info, :warning, :danger]

    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = type.to_sym
      type = :success if type == :notice
      type = :danger  if type == :alert
      type = :danger  if type == :error
      next unless alert_types.include?(type)

      tag_class = options.extract!(:class)[:class]
      tag_options = {
        class: "alert fade in alert-#{type} #{tag_class}"
      }.merge(options)

      close_button = content_tag(:button, raw("&times;"), type: "button", class: "close", "data-dismiss" => "alert")

      Array(message).each do |msg|
        text = content_tag(:div, close_button + sanitize(msg), tag_options)
        flash_messages << text if msg
      end
    end
    flash_messages.join("\n").html_safe
  end

end
