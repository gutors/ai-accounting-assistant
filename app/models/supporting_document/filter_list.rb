class SupportingDocument
  module FilterList
    SORT_COLUMNS = {
      "date" => :document_on,
      "amount" => :amount_cents
    }.freeze

    def filter_list(q: nil, kind: nil, date_from: nil, date_to: nil, sort: nil, dir: nil)
      relation = with_attached_photo.with_attached_xml
      query = q.to_s.strip
      relation = relation.where("payee ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
      relation = relation.where(kind: kind.to_s) if kinds.key?(kind.to_s)
      from_date = parse_filter_date(date_from)
      relation = relation.where("document_on >= ?", from_date) if from_date
      to_date = parse_filter_date(date_to)
      relation = relation.where("document_on <= ?", to_date) if to_date

      sort_col = SORT_COLUMNS.fetch(sort.to_s, :document_on)
      sort_dir = dir.to_s == "asc" ? :asc : :desc
      relation.reorder(sort_col => sort_dir, id: sort_dir)
    end

    def parse_filter_date(value)
      return value if value.is_a?(Date)
      return if value.blank?

      Date.iso8601(value.to_s)
    rescue ArgumentError, Date::Error
      nil
    end
  end
end
