class LocationsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:hud]

  def hud
    @loc = Location.find(params[:id])
    if (params[:key] == @loc.receipt_key) or (!current_volunteer.nil? and (current_volunteer.region_admin?(@loc.region) or current_volunteer.super_admin?))
      @schedules = ScheduleChain.for_location(@loc)
      if @loc.is_donor
        @logs = Log.at(@loc).to_a
      else
        @logs = Log.at(@loc).to_a.keep_if{ |x| x.weight_sum.to_f > 0 }
      end
      render :hud
    else
      flash[:notice] = "Sorry, the key you're using is expired or you're not authorized to do that"
      redirect_to(root_path)
      return
    end
  end

  def donors
    index(Location::LocationType.invert["Donor"],"Donors")
  end

  def hubs
    index(Location::LocationType.invert["Hub"],"Hubs")
  end

  def buyers
    index(Location::LocationType.invert["Buyer"],"Buyers")
  end

  def sellers
    index(Location::LocationType.invert["Seller"],"Sellers")
  end

  def recipients
    index(Location::LocationType.invert["Recipient"],"Recipients")
  end

  def index(location_type=nil,header="Locations")
    unless location_type.nil?
      @locations = Location.regional(current_volunteer.region_ids).where("location_type = ?",location_type)
    else
      @locations = Location.regional(current_volunteer.region_ids)
    end
    @header = header
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    render :index
  end

  def show
    @loc = Location.find(params[:id])
    unless current_volunteer.super_admin? or (current_volunteer.region_ids.include? @loc.region_id)
      flash[:notice] = "Can't view location for a region you're not assigned to..."
      respond_to do |format|
        format.html
        format.json { render json: {:error => 0, :message => flash[:notice] } }
      end
      return
    end
    respond_to do |format|
      format.html
      format.json { render json: @loc.attributes }
    end
  end

  def destroy
    @l = Location.find(params[:id])
    return unless check_permissions(@l)
    @l.active = false
    @l.save
    redirect_to(request.referrer)
  end

  def new
    @location = Location.new
    @location.region_id = params[:region_id]
    return unless check_permissions(@location)
    @action = "create"
    session[:my_return_to] = request.referer
    render :new
  end

  def check_permissions(l)
    unless current_volunteer.super_admin? or (current_volunteer.admin_region_ids.include? l.region_id) or
      flash[:notice] = "Not authorized to create/edit locations for that region"
      redirect_to(root_path)
      return false
    end
    return true
  end

  def create
    @location = Location.new(params[:location])
    @location.populate_detailed_hours_from_form params
    return unless check_permissions(@location)
    # can't set admin bits from CRUD controls
    if @location.save
      flash[:notice] = "Created successfully."
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

  def edit
    @location = Location.find(params[:id])
    return unless check_permissions(@location)
    @action = "update"
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @location = Location.find(params[:id])
    @location.populate_detailed_hours_from_form params
    return unless check_permissions(@location)
    # can't set admin bits from CRUD controls
    if @location.update_attributes(params[:location])
      flash[:notice] = "Updated Successfully."
      unless session[:my_return_to].nil?
        redirect_to session[:my_return_to]
      else
        index
      end
    else
      flash[:error] = "Update failed :("
      render :edit
    end
  end

end
