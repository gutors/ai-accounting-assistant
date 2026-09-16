module ApplicationHelper
  def format_reais(amount_cents)
    whole, frac = amount_cents.abs.divmod(100)
    grouped = whole.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
    "R$ #{grouped},#{format('%02d', frac)}"
  end
end
