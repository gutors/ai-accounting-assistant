module ApplicationHelper
  def format_reais(amount_cents)
    whole, frac = amount_cents.abs.divmod(100)
    grouped = whole.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
    "R$ #{grouped},#{format('%02d', frac)}"
  end

  # "2026-05" -> "maio de 2026"
  def month_title(year_month)
    l(Date.strptime(year_month, "%Y-%m"), format: :month_title)
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

  # The 44-digit chave de acesso as printed on the DANFE: groups of four.
  def format_chave(chave)
    chave.to_s.scan(/.{1,4}/).join(" ")
  end

  def readonly_if(reading)
    reading ? { readonly: true } : {}
  end
end
