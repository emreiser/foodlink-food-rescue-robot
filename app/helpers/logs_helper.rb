module LogsHelper

def log_volunteer_column(record)
  if record.volunteer.nil?
    link_to "Take Shift", "/logs/#{record.id}/take"
  else
    record.volunteer.name
  end
end

def log_volunteer_column_attributes(record)
  if record.volunteer.nil?
    {:style => 'background: yellow;'}
  else
    {}
  end
end

# Given a date, generates the corresponding log entries for that
# date based on the /current/ schedule
def generate_log_entries(d=Date.today)
  n = 0
  Schedule.where("day_of_week = ?",d.wday).each{ |s|
    next if s.recipient.nil? or s.donor.nil? 
    s.food_types.each{ |f|
      # don't insert a duplicate log entry if one already exists
      check = Log.where('"when" = ? AND schedule_id = ? AND food_type_id = ?',d,s.id,f.id)
      next if check.length > 0
      # create each scheduled log entry for the given day
      log = Log.new{ |l|
        l.schedule = s
        l.volunteer = s.volunteer
        l.donor = s.donor
        l.recipient = s.recipient
        l.region = s.region
        l.when = d
        l.food_type = f
      }
      n += 1 if log.save
    }
  }
  return n
end

# Sends an email to any volunteer who has a outstanding log entry
# from n or more days ago. Also sends an email to the admin summarizing
# all logs that have seen at least r reminders.
def send_reminder_emails(n=2,r=3)
  naughty_list = {}
  reminder_list = {}
  c = 0
  Log.where(:weight => nil).each{ |l| 
    days_past = (Date.today - l.when).to_i
    next unless days_past >= n
    l.num_reminders = 0 if l.num_reminders.nil?
    l.num_reminders += 1

    next if l.volunteer.nil?

    reminder_list[l.volunteer] = [] if reminder_list[l.volunteer].nil?
    reminder_list[l.volunteer].push(l)

    l.save

    if l.num_reminders >= r
      naughty_list[l.region] = [] if naughty_list[l.region].nil?
      naughty_list[l.region].push(l)
    end
  }
  reminder_list.each{ |v,logs|
    m = Notifier.volunteer_log_reminder(v,logs)
    m.deliver
    c += 1
  }
  if naughty_list.length > 0
    m = Notifier.admin_reminder_summary(naughty_list)
    m.deliver
  end
  return c
end

end
