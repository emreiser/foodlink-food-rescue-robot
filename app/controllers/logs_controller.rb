require "prawn/table"

class LogsController < ApplicationController

  before_filter :authenticate_volunteer!, :except => :stats_service
  before_filter :admin_only, :only => [:today,:tomorrow,:yesterday,:being_covered,:tardy,:receipt,:new,:create,:stats,:export]

  def mine_past
    index(Log.group_by_schedule(Log.past_for(current_volunteer.id)),"Your Past Shifts")
  end

  def mine_upcoming
    index(Log.group_by_schedule(Log.upcoming_for(current_volunteer.id)),"Your Upcoming Shifts")
  end

  def open
    index(Log.group_by_schedule(Log.needing_coverage(current_volunteer.region_ids)),"Open Shifts")
  end

  def by_day
    if params[:date].present?
      d = Date.civil(*params[:date].sort.map(&:last).map(&:to_i))
    else
      n = params[:n].present? ? params[:n].to_i : 0
      d = Time.zone.today+n
    end
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" = '#{d.to_s}'")),"Shifts on #{d.strftime("%A, %B %-d")}")
  end

  def last_ten
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" >= '#{(Time.zone.today-10).to_s}' AND \"when\" <= '#{(Time.zone.today).to_s}'")),"Last 10 Days of Shifts")
  end

  def being_covered
    index(Log.group_by_schedule(Log.being_covered(current_volunteer.region_ids)),"Being Covered")
  end

  def todo
    index(Log.group_by_schedule(Log.past_for(current_volunteer.id).where("\"when\" < current_date AND NOT complete")),"Your To Do Shift Reports")
  end

  def tardy
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" < current_date AND NOT complete and num_reminders >= 3","Missing Data (>= 3 Reminders)")),"Missing Data (>= 3 Reminders)")
  end

  def index(shifts=nil,header="Entire Log")
    filter = filter.nil? ? "" : " AND #{filter}"
    @shifts = []
    if current_volunteer.region_ids.length > 0
      @shifts = shifts.nil? ? Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")})")) : shifts
    end
    @header = header
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    respond_to do |format|
      format.json { render json: @shifts }
      format.html { render :index }
    end
  end

  def stats
    @regions = current_volunteer.admin_regions(true)
    @regions = Region.all if current_volunteer.admin? and @regions.empty?
    @first_recorded_pickup = Log.where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(",")})").
      order("logs.when ASC").limit(1)
    @pounds_per_year = Log.joins(:log_parts).select("extract(YEAR from logs.when) as year, sum(weight)").
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group("year").order("year ASC").collect{ |l| [l.year,l.sum] }
    @pounds_per_month = Log.joins(:log_parts).select("date_trunc('month',logs.when) as month, sum(weight)").
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group("month").order("month ASC").collect{ |l| [l.month.strftime("%Y-%m"),l.sum] }
    @transport_per_year = {}
    @transport_years = []
    @transport_data = Log.joins(:transport_type).select("extract(YEAR from logs.when) as year, transport_types.name, count(*)").
      where("complete AND region_id in (#{@regions.collect{ |r| r.id }.join(',')})").
      group("name,year").order("name,year ASC")
    @transport_years.sort!
    @transport_data.each{ |l|
      @transport_years << l.year unless @transport_years.include? l.year
      @transport_per_year[l.name] = [] if @transport_per_year[l.name].nil?
    }
    @transport_per_year.keys.each{ |k|
      @transport_per_year[k] = @transport_years.collect{ |y| 0 }
    }
    @transport_data.each{ |l|
      @transport_per_year[l.name][@transport_years.index(l.year)] = l.count.to_i
    }
  end

  def stats_service
    case params[:what]
    when 'poundage'
      if params[:region_id].nil?
        t = LogPart.sum(:weight) + Region.where("prior_lbs_rescued IS NOT NULL").sum("prior_lbs_rescued")
      else
        r = params[:region_id]
        @region = Region.find(r)
        t = Log.joins(:log_parts).where("region_id = ? AND complete",r).sum("weight").to_f
        t += @region.prior_lbs_rescued.to_f unless @region.nil? or @region.prior_lbs_rescued.nil?
      end
      render :text => t.to_s
    when 'wordcloud'
      words = {}
      LogPart.select("description").where("description IS NOT NULL").each{ |l|
        l.description.strip.split(/\s*\,\s*/).each{ |w|
          w = w.strip.downcase.tr(',','')
          next if w =~ /(nothing|no |none)/ or w =~ /etc/ or w =~ /n\/a/ or w =~ /misc/
          # people cannot seem to spell the most delicious fruit correctly
          w = "avocados" if w == "avacados" or w == "avocadoes" or w == "avocado"
          words[w] = 0 if words[w].nil?
          words[w] += 1
        }
      }
      render :text => words.collect{ |k,v| (v >= 10) ? "#{k}:#{v}" : nil }.compact.join(",")
    when 'transport'
      rq = ""
      wq = ""
      unless params[:region_id].nil?
        rq = "AND region_id=#{params[:region_id].to_i}"
      end
      unless params[:timespan].nil?
        if params[:timespan] == "month"
          wq = "AND \"when\" > NOW() - interval '1 month'"
        end
      end
      noncar = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name != 'Car') #{rq} #{wq}").count.to_f
      car = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name = 'Car') #{rq} #{wq}").count.to_f
      render :text => "#{100.0*noncar/(noncar+car)} #{100.0*car/(noncar+car)}"
    else
      render :text => "NO"
    end
  end

  def destroy
    @l = Log.find(params[:id])
    unless current_volunteer.any_admin? @l.region
      flash[:notice] = "Not authorized to delete log items for that region"
      redirect_to(root_path)
      return
    end
    @l.destroy
    redirect_to(request.referrer)
  end

  def new
    @region = Region.find(params[:region_id])
    unless current_volunteer.any_admin? @region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    @log = Log.new
    @log.region = @region
    @action = "create"
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :new
  end

  def create
    @log = Log.create(params[:log])
    @region = @log.region
    @food_types = @region.food_types.collect{ |e| [e.name,e.id] }
    @scale_types = @region.scale_types.collect{ |e| [e.name,e.id] }
    if @scale_types.length<2 and @log.scale_type_id.nil?
      @log.scale_type_id = @region.scale_types.first.id
    end
    unless current_volunteer.any_admin? @log.region
      flash[:error] = "Not authorized to create logs for that region"
      redirect_to(root_path)
      return
    end
    @log.reload
    finalize_log(@log)
    if @log.save
      flash[:notice] = "Created successfully."
      email_log(@log)
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def show
    @log = Log.find(params[:id])
    respond_to do |format|
      format.html
      format.json {
        attrs = {}
        attrs[:log] = @log.attributes
        attrs[:log][:recipient_ids] = @log.recipient_ids
        attrs[:log][:volunteer_ids] = @log.volunteer_ids
        attrs[:log][:volunteer_names] = @log.volunteers.collect{ |v| v.name }
        attrs[:schedule] = @log.schedule_chain.attributes unless @log.schedule_chain.nil?
        attrs[:log_parts] = {}
        @log.log_parts.each{ |lp| attrs[:log_parts][lp.id] = lp.attributes }
        render json: attrs
      }
    end
  end

  def edit
    @log = Log.find(params[:id])
    unless current_volunteer.any_admin? @log.region or @log.volunteers.include? current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      redirect_to(root_path)
      return
    end
    @region = @log.region
    @action = "update"
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :edit
  end

  def update
    @log = Log.find(params[:id])
    @region = @log.region
    @action = "update"
    set_vars_for_form @region

    unless current_volunteer.any_admin? @log.region or @log.volunteers.include? current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      respond_to do |format|
        format.json { render json: {:error => 1, :message => flash[:notice] } }
        format.html { redirect_to(root_path) }
      end
      return
    end

    if @log.update_attributes(log_params)

      # Delete volunteers removed from log
      unless params[:log][:log_volunteers_attributes].nil?
        delete_volunteers = []
        params[:log][:log_volunteers_attributes].collect{ |k,v|
          delete_volunteers << LogVolunteer.find(v["id"].to_i) if v["volunteer_id"].nil?
        }
        @log.log_volunteers -= delete_volunteers
      end

      finalize_log(@log)

      if @log.save
        if @log.complete
          email_log(@log)
          flash[:notice] = "Updated Successfully. All done!"
        else
          flash[:warning] = %Q[Saved, but some weights/counts still needed to complete this log. <a href="/logs/#{@log.id}/edit">Finish it here.</a>]
        end
        respond_to do |format|
          format.json { render json: {error: 0, message: flash[:notice] } }
          format.html { render :show}
        end
      else
        flash[:error] = "Failed to mark as complete."
        respond_to do |format|
          format.json { render json: {error: 2, message: flash[:notice] } }
          format.html { render :edit }
        end
      end
    else
      flash[:error] = "Update failed :("
      respond_to do |format|
        format.json { render json: {error: 1, message: flash[:notice] } }
        format.html { render :edit }
      end
    end
  end

  # can be given a single id or a list of ids
  def take
    unless params[:ids].present?
      logs = [Log.find(params[:id])]
    else
      logs = Log.find(params[:ids])
    end

    volunteer_regions = current_volunteer.regions.pluck(:id).uniq.sort
    log_regions = logs.flat_map {|log| log.region.id }.uniq.sort

    if log_regions == volunteer_regions
      logs.each do |log|
        LogVolunteer.create(volunteer: current_volunteer, covering: true, log: log)
      end
      flash[:notice] = "Successfully took a shift with #{logs.length} donor(s)."
      logs.each do |log|
        if log.region.receive_log_emails
          m = Notifier.email_one_time_shift(log, current_volunteer)
          m.deliver
        end
      end
    else
      flash[:notice] = "Cannot take shifts for regions that you aren't assigned to!"
    end

    respond_to do |format|
      format.json {
        render json: {error: 0, message: flash[:notice]}
      }
      format.html {
        redirect_to :back
      }
    end

  end

  # can be given a single id or a list of ids
  def leave
    unless params[:ids].present?
      l = [Log.find(params[:id])]
    else
      l = params[:ids].collect{ |i| Log.find(i) }
    end
    if l.all?{ |x| current_volunteer.in_region? x.region_id }
      l.each do |x|
        if x.has_volunteer? current_volunteer
          LogVolunteer.where(:volunteer_id=>current_volunteer.id, :log_id=>x.id).each{ |lv|
            lv.active = false
            lv.save
          }
        end
      end
      flash[:notice] = "You left a pickup with #{l.length} donor(s)."
    else
      flash[:error] = "Cannot leave that pickup since you are not a member of that region!"
    end
    redirect_to :back
  end

  def receipt
    if Date.valid_date?(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
      @start_date = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    else
      flash[:notice] = "Invalid Date Set for Start Date. Please try again!"
      return redirect_to(request.referer || root_path)
    end

    if Date.valid_date?(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
      @stop_date = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    else
      flash[:notice] = "Invalid Date Set for End Date. Please try again!"
      return redirect_to(request.referer || root_path)
    end

    @loc = Location.find(params[:location_id])

    unless current_volunteer.any_admin?(@loc.region)
      flash[:notice] = "Cannot generate receipt for donors/receipients in other regions than your own!"
      redirect_to(root_path)
      return
    end

    @logs = Log.where("logs.when >= ? AND logs.when <= ? AND donor_id = ? AND complete",@start_date,@stop_date,@loc.id)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new
        pdf.font_size 20
        pdf.text @loc.region.title, :align => :center

        unless @loc.region.tagline.nil?
          pdf.move_down 10
          pdf.font_size 12
          pdf.text @loc.region.tagline, :align => :center
        end

        unless @loc.region.address.nil?
          pdf.font_size 10
          pdf.font "Times-Roman"
          pdf.move_down 10
          pdf.text "#{@loc.region.address.tr("\n",", ")}", :align => :center
        end

        unless @loc.region.website.nil?
          pdf.move_down 5
          pdf.text "#{@loc.region.website}", :align => :center
        end
        unless @loc.region.phone.nil?
          pdf.move_down 5
          pdf.text "#{@loc.region.phone}", :align => :center
        end
        pdf.move_down 10
        pdf.text "Federal Tax-ID: #{@loc.region.tax_id}", :align => :right
        pdf.text "Receipt period: #{@start_date} to #{@stop_date}", :align => :left
        pdf.move_down 5
        pdf.text "Receipt for: #{@loc.name}", :align => :center
        pdf.move_down 10
        pdf.font "Helvetica"
        sum = 0.0
        pdf.table([["Date","Description","Log #","Weight (lbs)"]] + @logs.collect{ |l|
          sum += l.summed_weight
          l.summed_weight == 0 ? nil : [l.when,l.log_parts.collect{ |lp| lp.food_type.nil? ? nil : lp.food_type.name }.compact.join(","),l.id,l.summed_weight]
        }.compact + [["Total:","","",sum]])
        pdf.move_down 20
        pdf.font_size 10
        pdf.font "Courier", :style => :italic
        pdf.text "This receipt was generated by The Food Link Robot at #{Time.zone.now.to_s}. The weights included are estimates.", :align => :center
        send_data pdf.render
      end
    end
  end

  def export
    @start_date = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    @stop_date = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    @regions = current_volunteer.admin_regions(true)
    @types = FoodType.all.collect{|f| {id: f.id, name: f.name}}

    self.response.headers["Content-Type"] ||= 'text/csv'
    self.response.headers["Content-Disposition"] = "attachment; filename=export.csv"
    self.response.headers["Content-Transfer-Encoding"] = "binary"
    self.response.headers["Last-Modified"] = Time.now.ctime.to_s

    self.response_body = Enumerator.new do |yielder|
      yielder << ["Id","Date",@types.map{|t| t[:name]},"Total weight","Donor","Recipients","Volunteers","Hours spent"].flatten.to_csv

      Log.where("logs.when >= ? AND logs.when <= ? AND complete AND region_id IN (#{@regions.collect{ |r| r.id }.join(",")})",@start_date,@stop_date).find_each do |log|
        lps = log.log_parts
        num_boxes = @types.map{ |t| "#{lps.where(food_type_id: t[:id]).compact.inject(0) { |sum, x| (sum + x[:num_boxes]) if x[:num_boxes] }}"}
        yielder << [
          log.id,
          log.when,
          num_boxes,
          log.summed_weight,
          log.donor.nil? ? "Unknown" : log.donor.name,
          log.recipients.collect{ |r| r.nil? ? "Unknown" : r.name }.join(":"),
          log.volunteers.collect{ |r| r.nil? ? "Unknown" : r.name }.join(":"),
          log.hours_spent
        ].flatten.to_csv
      end
    end
  end

  private

    def log_params
      params.require(:log).permit(
        :region_id, :schedule_chain_id, :num_volunteers, :when, :donor_id, :hours_spent,
        :flag_for_admin, :info_for_next_day, :volunteer_feedback, :notes, :why_zero,
        log_volunteers_attributes: [:id, :volunteer_id, :operations_lead, :_destroy],
        log_recipients_attributes: [:id, :recipient_id],
        log_parts_attributes: [:food_type_id, :num_boxes, :description, :id, :_destroy])
    end

    def parse_and_create_log_parts(params,log)
      ret = []
      params["log"]["log_parts_attributes"].each{ |dc,lpdata|
        empty = lpdata["food_type_id"].blank? || lpdata["num_boxes"].blank?
        next if lpdata["id"].blank? and empty
        lp = lpdata["id"].present? ? LogPart.find(lpdata["id"].to_i) : LogPart.new 
        lp.num_boxes = lpdata["num_boxes"]
        lp.description = lpdata["description"]
        lp.food_type_id = lpdata["food_type_id"].to_i
        lp.log_id = log.id
        ret.push lp
        lp.save
      } unless params["log_parts"].nil?
      LogPart.delete(log.log_parts - ret)
      ret
    end

    def finalize_log(log)
      # mark as complete if deserving
      filled_count = 0
      required_unfilled = 0

      log.log_parts.each{ |lp|
        required_unfilled += 1 if lp.required && lp.weight.nil? && lp.count.nil?
        filled_count += 1 unless lp.num_boxes.nil? && lp.count.nil?
      }

      log.complete = filled_count > 0 && required_unfilled == 0
    end

    def email_log(log)
      if log.region.receive_log_emails
        m = Notifier.email_log_report(log.region, log, current_volunteer)
        m.deliver
      end
    end

    def admin_only
      redirect_to(root_path) unless current_volunteer.any_admin?
    end

end