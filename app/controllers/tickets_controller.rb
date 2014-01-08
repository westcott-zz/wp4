class TicketsController < ApplicationController
  before_filter :require_user
  before_filter :set_current_tab, :only => [ :index, :show ]
  before_filter :update_sidebar, :only => :index


  # GET /tickets
  #----------------------------------------------------------------------------
  def index
    @view = params[:view] || "pending"
    @tickets = Ticket.find_all_grouped(current_user, @view)
    #@tickets = Ticket.all

    respond_with @tickets do |format|
      format.xls { render :layout => 'header' }
      format.csv { render :csv => @tickets.map(&:second).flatten }
      format.xml { render :xml => @tickets, :except => [:subscribed_users] }
    end
  end

  # GET /tickets/1
  #----------------------------------------------------------------------------
  def show
    @ticket = Ticket.tracked_by(current_user).find(params[:id])

    respond_with(@ticket)
  end

  # GET /tickets/new
  #----------------------------------------------------------------------------
  def new
    @view = params[:view] || "pending"
    @ticket = Ticket.new
    @bucket = Setting.unroll(:ticket_bucket)[1..-1] << [ t(:due_specific_date, :default => 'On Specific Date...'), :specific_time ]
    @category = Setting.unroll(:ticket_category)

    if params[:related]
      model, id = params[:related].split(/_(\d+)/)
      if related = model.classify.constantize.my.find_by_id(id)
        instance_variable_set("@asset", related)
      else
        respond_to_related_not_found(model) and return
      end
    end

    respond_with(@ticket)
  end

  # GET /tickets/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    @view = params[:view] || "pending"
    @ticket = Ticket.tracked_by(current_user).find(params[:id])
    @bucket = Setting.unroll(:ticket_bucket)[1..-1] << [ t(:due_specific_date, :default => 'On Specific Date...'), :specific_time ]
    @category = Setting.unroll(:ticket_category)
    @asset = @ticket.asset if @ticket.asset_id?

    if params[:previous].to_s =~ /(\d+)\z/
      @previous = Ticket.tracked_by(current_user).find_by_id($1) || $1.to_i
    end

    respond_with(@ticket)
  end

  # POST /tickets
  #----------------------------------------------------------------------------
  def create
    @view = params[:view] || "pending"
    @ticket = Ticket.new(params[:ticket]) # NOTE: we don't display validation messages for tickets.

    respond_with(@ticket) do |format|
      if @ticket.save
        update_sidebar if called_from_index_page?
      end
    end
  end

  # PUT /tickets/1
  #----------------------------------------------------------------------------
  def update
    @view = params[:view] || "pending"
    @ticket = Ticket.tracked_by(current_user).find(params[:id])
    @ticket_before_update = @ticket.clone

    if @ticket.due_at && (@ticket.due_at < Date.today.to_time)
      @ticket_before_update.bucket = "overdue"
    else
      @ticket_before_update.bucket = @ticket.computed_bucket
    end

    respond_with(@ticket) do |format|
      if @ticket.update_attributes(params[:ticket])
        @ticket.bucket = @ticket.computed_bucket
        if called_from_index_page?
          if Ticket.bucket_empty?(@ticket_before_update.bucket, current_user, @view)
            @empty_bucket = @ticket_before_update.bucket
          end
          update_sidebar
        end
      end
    end
  end

  # DELETE /tickets/1
  #----------------------------------------------------------------------------
  def destroy
    @view = params[:view] || "pending"
    @ticket = Ticket.tracked_by(current_user).find(params[:id])
    @ticket.destroy

    # Make sure bucket's div gets hidden if we're deleting last ticket in the bucket.
    if Ticket.bucket_empty?(params[:bucket], current_user, @view)
      @empty_bucket = params[:bucket]
    end

    update_sidebar if called_from_index_page?
    respond_with(@ticket)
  end

  # PUT /tickets/1/complete
  #----------------------------------------------------------------------------
  def complete
    @ticket = Ticket.tracked_by(current_user).find(params[:id])
    @ticket.update_attributes(:completed_at => Time.now, :completed_by => current_user.id) if @ticket

    # Make sure bucket's div gets hidden if it's the last completed ticket in the bucket.
    if Ticket.bucket_empty?(params[:bucket], current_user)
      @empty_bucket = params[:bucket]
    end

    update_sidebar unless params[:bucket].blank?
    respond_with(@ticket)
  end

  # POST /tickets/auto_complete/query                                        AJAX
  #----------------------------------------------------------------------------
  # Handled by ApplicationController :auto_complete

  # Ajax request to filter out a list of tickets.                            AJAX
  #----------------------------------------------------------------------------
  def filter
    @view = params[:view] || "pending"

    update_session do |filters|
      if params[:checked].true?
        filters << params[:filter]
      else
        filters.delete(params[:filter])
      end
    end
  end

private

  # Yields array of current filters and updates the session using new values.
  #----------------------------------------------------------------------------
  def update_session
    name = "filter_by_ticket_#{@view}"
    filters = (session[name].nil? ? [] : session[name].split(","))
    yield filters
    session[name] = filters.uniq.join(",")
  end

  # Collect data necessary to render filters sidebar.
  #----------------------------------------------------------------------------
  def update_sidebar
    @view = params[:view]
    @view = "pending" unless %w(pending assigned completed).include?(@view)
    @ticket_total = Ticket.totals(current_user, @view)

    # Update filters session if we added, deleted, or completed a ticket.
    if @ticket
      update_session do |filters|
        if @empty_bucket  # deleted, completed, rescheduled, or reassigned and need to hide a bucket
          filters.delete(@empty_bucket)
        elsif !@ticket.deleted_at && !@ticket.completed_at # created new ticket
          filters << @ticket.computed_bucket
        end
      end
    end

    # Create default filters if filters session is empty.
    name = "filter_by_ticket_#{@view}"
    unless session[name]
      filters = @ticket_total.keys.select { |key| key != :all && @ticket_total[key] != 0 }.join(",")
      session[name] = filters unless filters.blank?
    end
  end
end
