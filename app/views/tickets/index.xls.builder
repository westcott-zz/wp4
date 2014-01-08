xml.Worksheet 'ss:Name' => I18n.t(:tab_tickets) do
  xml.Table do
    unless @tickets.empty?
      # Header.
      xml.Row do
        heads = %w{name
                   due
                   date_created
                   date_updated
                   completed
                   user
                   assigned_to
                   category
                   background_info}

        heads.each do |head|
          xml.Cell do
            xml.Data I18n.t(head),
                     'ss:Type' => 'String'
          end
        end
      end

      # Rows.
      @tickets.map(&:second).flatten.each do |ticket|
        xml.Row do
          data = [ticket.title,
                  I18n.t(ticket.computed_bucket),
                  ticket.created_at,
                  ticket.updated_at,
                  ticket.completed_at,
                  ticket.user.try(:name),
                  ticket.assignee.try(:name),
                  ticket.category,
                  ticket.background_info]

          data.each do |value|
            xml.Cell do
              xml.Data value,
                       'ss:Type' => "#{value.respond_to?(:abs) ? 'Number' : 'String'}"
            end
          end
        end
      end
    end
  end
end
