module ApplicationHelper
  def format_reais(amount_cents)
    BrlCents.format_reais(amount_cents)
  end

  # "2026-05" -> "maio de 2026"
  def month_title(year_month)
    l(Date.strptime(year_month, "%Y-%m"), format: :month_title)
  end

  # "2026-09" -> "Setembro - 09/2026"
  def month_list_title(year_month)
    date = Date.strptime(year_month, "%Y-%m")
    "#{I18n.t("date.month_names")[date.month].upcase_first} - #{date.strftime("%m/%Y")}"
  end

  def openable_month_options(today = Date.current)
    first = today.beginning_of_month.prev_month(12)
    (0..24).map do |offset|
      year_month = first.next_month(offset).strftime("%Y-%m")
      [ month_title(year_month), year_month ]
    end
  end

  def previous_calendar_year_month(today = Date.current)
    today.beginning_of_month.prev_month.strftime("%Y-%m")
  end

  # Ledger row status, in the order the month page decides it.
  def payment_status(payment)
    if payment.missing_document?
      "missing"
    elsif payment.match_id.present?
      "matched"
    elsif payment.bank_fee?
      "bank_fee"
    elsif payment.accountant_fee?
      "accountant_fee"
    elsif payment.extra_exception_kind_id.present?
      "extra"
    end
  end

  # The word the month page prints for a status; one line, truncated with its title.
  def payment_status_word(payment, status)
    case status
    when "missing" then "Documento faltante"
    when "matched" then "Casado"
    when "bank_fee" then "Tarifa bancária"
    when "accountant_fee" then "Honorário do contador"
    when "extra" then payment.extra_exception_kind.name
    end
  end

  # The 44-digit chave de acesso as printed on the DANFE: groups of four.
  def format_chave(chave)
    chave.to_s.scan(/.{1,4}/).join(" ")
  end

  def amount_field_value(cents)
    BrlCents.field_value(cents)
  end

  def people_role_count(count, singular, plural)
    "#{count} #{count == 1 ? singular : plural}"
  end

  def people_book_meta(coordinator_count:, submitter_count:, invite_count:, failed_count:)
    parts = [ "#{coordinator_count + submitter_count} pessoas" ]
    parts << "#{invite_count} convites" if invite_count.positive?
    parts << "#{failed_count} falhou envio" if failed_count.positive?
    parts.join(" · ")
  end

  def principal_nav_link(label, path)
    current = current_page?(path) || (path == "/" && content_for?(:home_desk))
    link_to label, path, aria: { current: ("page" if current) },
      class: [ "text-ink hover:underline underline-offset-2", ("font-semibold underline" if current) ]
  end

  def ledger_sort_cell(label, column:, current_sort:, current_dir:, base_path:, filter_params: {}, align: :left, sort_param: :sort, dir_param: :dir)
    active = current_sort.to_s == column.to_s
    dir = current_dir.to_s == "asc" ? "asc" : "desc"
    aria_sort = active ? (dir == "asc" ? "ascending" : "descending") : "none"
    cell_class = align == :right ? "ledger-amount" : nil

    tag.span(class: cell_class, aria: { sort: aria_sort }) do
      ledger_sort_link(
        label,
        column: column,
        current_sort: current_sort,
        current_dir: dir,
        base_path: base_path,
        filter_params: filter_params,
        sort_param: sort_param,
        dir_param: dir_param
      )
    end
  end

  def ledger_sort_link(label, column:, current_sort:, current_dir:, base_path:, filter_params: {}, sort_param: :sort, dir_param: :dir)
    active = current_sort.to_s == column.to_s
    dir = current_dir.to_s == "asc" ? "asc" : "desc"
    next_dir = active && dir == "desc" ? "asc" : "desc"
    icon_state = active ? dir : "none"
    query = filter_params.to_h.symbolize_keys.compact_blank
    query[sort_param] = column.to_s
    query[dir_param] = next_dir
    href = "#{base_path}?#{query.to_query}"

    link_to href, class: [ "ledger-sort-link", ("sort-key" if active) ].compact.join(" "), data: { sort_column: column } do
      safe_join([ tag.span(label), ledger_sort_icon_svg(icon_state) ])
    end
  end

  def ledger_sort_icon_svg(state)
    case state
    when "asc"
      tag.svg(viewBox: "0 0 12 12", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true", class: "ledger-sort-icon", data: { sort_icon: "asc" }) do
        safe_join([
          tag.path(d: "M6 9.5V2.5"),
          tag.path(d: "M3 5.5L6 2.5L9 5.5")
        ])
      end
    when "desc"
      tag.svg(viewBox: "0 0 12 12", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true", class: "ledger-sort-icon", data: { sort_icon: "desc" }) do
        safe_join([
          tag.path(d: "M6 2.5V9.5"),
          tag.path(d: "M3 6.5L6 9.5L9 6.5")
        ])
      end
    else
      tag.svg(viewBox: "0 0 12 12", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true", class: "ledger-sort-icon", data: { sort_icon: "none" }) do
        safe_join([
          tag.path(d: "M3.5 4.5L6 2L8.5 4.5"),
          tag.path(d: "M3.5 7.5L6 10L8.5 7.5")
        ])
      end
    end
  end

  def ledger_edit_icon_link(path, label: "Editar")
    link_to path, aria: { label: label }, title: label, class: "ledger-action-icon text-caixa" do
      safe_join([
        tag.svg(viewBox: "0 0 16 16", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true") do
          tag.path(d: "M11.5 2.5a1.414 1.414 0 0 1 2 2L5 13H2.5v-2.5L11.5 2.5z")
        end,
        tag.span(label, class: "sr-only")
      ])
    end
  end

  def ledger_delete_icon_button(path, label: "Excluir", confirm: nil, params: {})
    form_opts = confirm ? { data: { turbo_confirm: confirm } } : {}
    button_to path, method: :delete, params: params, aria: { label: label }, title: label, form: form_opts, class: "ledger-action-icon text-margem" do
      safe_join([
        tag.svg(viewBox: "0 0 16 16", fill: "none", stroke: "currentColor", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true") do
          safe_join([
            tag.path(d: "M2.5 4h11"),
            tag.path(d: "M5.5 4V2.5h5V4"),
            tag.path(d: "M4 4l.75 9.5h6.5L12 4"),
            tag.path(d: "M6.75 6.75v4.25"),
            tag.path(d: "M9.25 6.75v4.25")
          ])
        end,
        tag.span(label, class: "sr-only")
      ])
    end
  end
end
