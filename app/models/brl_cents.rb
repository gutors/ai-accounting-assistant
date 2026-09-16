class BrlCents
  def self.parse(value)
    return if value.nil?

    parse_string(value.is_a?(String) ? value : value.to_s)
  end

  def self.parse_string(string)
    s = string.to_s.strip.gsub(/[\s\u00a0]/, "").delete("R$")
    return if s.empty?

    negative = s.start_with?("-")
    s = s.sub(/\A-/, "")
    cents = if s.include?(",")
      whole, frac = s.split(",", 2)
      whole.to_s.delete(".").to_i * 100 + frac_to_cents(frac)
    elsif s.include?(".")
      whole, frac = s.split(".", 2)
      whole.to_i * 100 + frac_to_cents(frac)
    else
      s.to_i * 100
    end
    (negative ? -cents : cents).abs
  end

  def self.frac_to_cents(frac)
    digits = frac.to_s.gsub(/\D/, "")
    return 0 if digits.empty?

    padded = digits.ljust(3, "0")
    major = padded[0, 2].to_i
    padded[2].to_i >= 5 ? major + 1 : major
  end
  private_class_method :parse_string, :frac_to_cents
end
