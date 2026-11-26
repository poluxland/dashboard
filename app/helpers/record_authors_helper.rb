module RecordAuthorsHelper
  LABELS = [ "Creado por", "Última modificación por" ].freeze

  def record_author_labels
    signed_in? ? LABELS : []
  end

  def record_author_values(record)
    signed_in? ? record.values_at(:created_by_email, :updated_by_email) : []
  end

  def record_author_headers
    safe_join(record_author_labels.map { |label| tag.th(label, scope: "col", class: "text-nowrap") })
  end

  def record_author_cells(record)
    safe_join(record_author_values(record).map { |email| tag.td(email, class: "text-break") })
  end

  def record_author_details(record)
    return unless signed_in?

    tag.dl(class: "row small mb-2") do
      safe_join(LABELS.zip(record_author_values(record)).flat_map do |label, email|
        [ tag.dt(label, class: "col-sm-4"), tag.dd(email, class: "col-sm-8 text-break") ]
      end)
    end
  end
end
