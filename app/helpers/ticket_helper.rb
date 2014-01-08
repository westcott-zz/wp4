module TicketHelper

  # Sidebar checkbox control for filtering tickets by due date -- used for
  # pending and assigned views only.
  #----------------------------------------------------------------------------
  def ticket_filter_checkbox(view, filter, count)
    name = "filter_by_ticket_#{view}"
    checked = (session[name] ? session[name].split(",").include?(filter.to_s) : count > 0)
    onclick = remote_function(
      :url      => { :action => :filter, :view => view },
      :with     => "'filter='+this.value+'&checked='+this.checked",
      :loading  => "$('loading').show()",
      :complete => "$('loading').hide()"
    )
    check_box_tag("filters[]", filter, checked, :onclick => onclick)
  end

  #----------------------------------------------------------------------------
  def filtered_out?(view, filter = nil)
    name = "filter_by_ticket_#{view}"
    if filter
      filters = (session[name].nil? ? [] : session[name].split(","))
      !filters.include?(filter.to_s)
    else
      session[name].blank?
    end
  end

  #----------------------------------------------------------------------------
  def link_to_ticket_edit(ticket, bucket)
    link_to(t(:edit), edit_ticket_path(ticket),
      :method => :get,
      :with   => "{ bucket: '#{bucket}', view: '#{@view}', previous: crm.find_form('edit_ticket') }",
      :remote => true
    )
  end

  #----------------------------------------------------------------------------
  def link_to_ticket_delete(ticket, bucket)
    link_to(t(:delete) + "!", ticket_path(ticket),
      :method => :delete,
      :with   => "{ bucket: '#{bucket}', view: '#{@view}' }",
      :before => visual_effect(:highlight, dom_id(ticket), :startcolor => "#ffe4e1"),
      :remote => true
    )
  end

  #----------------------------------------------------------------------------
  def link_to_ticket_complete(pending, bucket)
    onclick = %Q/$("#{dom_id(pending, :name)}").style.textDecoration="line-through";/
    onclick << remote_function(:url => complete_ticket_path(pending), :method => :put, :with => "'bucket=#{bucket}'")
  end

  # Ticket summary for RSS/ATOM feed.
  #----------------------------------------------------------------------------
  def ticket_summary(ticket)
    summary = [ ticket.category.blank? ? t(:other) : t(ticket.category) ]
    if @view != "completed"
      if @view == "pending" && ticket.user != current_user
        summary << t(:ticket_from, ticket.user.full_name)
      elsif @view == "assigned"
        summary << t(:ticket_from, ticket.assignee.full_name)
      end
      summary << "#{t(:related)} #{ticket.asset.name} (#{ticket.asset_type.downcase})" if ticket.asset_id?
      summary << if ticket.bucket == "due_asap"
        t(:ticket_due_now)
      elsif ticket.bucket == "due_later"
        t(:ticket_due_later)
      else
        l(ticket.due_at.localtime, :format => :mmddhhss)
      end
    else # completed
      summary << "#{t(:related)} #{ticket.asset.name} (#{ticket.asset_type.downcase})" if ticket.asset_id?
      summary << t(:ticket_completed_by,
                   :time_ago => distance_of_time_in_words(ticket.completed_at, Time.now),
                   :date     => l(ticket.completed_at.localtime, :format => :mmddhhss),
                   :user     => ticket.completor.full_name)
    end
    summary.join(', ')
  end

  #----------------------------------------------------------------------------
  def hide_ticket_and_possibly_bucket(id, bucket)
    update_page do |page|
      page[id].replace ""

      if Ticket.bucket_empty?(bucket, current_user, @view)
        page["list_#{bucket}"].visual_effect :fade, :duration => 0.5
      end
    end
  end

  #----------------------------------------------------------------------------
  def replace_content(ticket, bucket = nil)
    partial = (ticket.assigned_to && ticket.assigned_to != current_user.id) ? "assigned" : "pending"
    update_page do |page|
      page[dom_id(ticket)].replace_html :partial => "tickets/#{partial}", :collection => [ ticket ], :locals => { :bucket => bucket }
    end
  end

  #----------------------------------------------------------------------------
  def insert_content(ticket, bucket, view)
    update_page do |page|
      page["list_#{bucket}"].show
      page.insert_html :top, bucket, :partial => view, :collection => [ ticket ], :locals => { :bucket => bucket }
      page[dom_id(ticket)].visual_effect :highlight, :duration => 1.5
    end
  end

  #----------------------------------------------------------------------------
  def tickets_flash(message)
    update_page do |page|
      page[:flash].replace_html message
      page.call "crm.flash", :notice, true
    end
  end

  #----------------------------------------------------------------------------
  def reassign(id)
    update_page do |page|
      if @view == "pending" && @ticket.assigned_to != current_user.id
        page << hide_ticket_and_possibly_bucket(id, @ticket_before_update.bucket)
        page << tickets_flash("#{t(:ticket_assigned, @ticket.assignee.full_name)} (" << link_to(t(:view_assigned_tickets), url_for(:controller => :tickets, :view => :assigned)) << ").")
      elsif @view == "assigned" && @ticket.assigned_to.blank?
        page << hide_ticket_and_possibly_bucket(id, @ticket_before_update.bucket)
        page << tickets_flash("#{t(:ticket_pending)} (" << link_to(t(:view_pending_tickets), tickets_url) << ").")
      else
        page << replace_content(@ticket, @ticket.bucket)
      end
      page << refresh_sidebar(:index, :filters)
    end
  end

  #----------------------------------------------------------------------------
  def reschedule(id)
    update_page do |page|
      page << hide_ticket_and_possibly_bucket(id, @ticket_before_update.bucket)
      page << insert_content(@ticket, @ticket.bucket, @view)
      page << refresh_sidebar(:index, :filters)
    end
  end

end
