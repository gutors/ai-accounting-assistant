module NormalizedEmail
  def self.normalize(value)
    value.to_s.strip.downcase.presence
  end

  def self.valid?(value)
    normalized = normalize(value)
    normalized.present? && normalized.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
