require "nokogiri"

class AuthorizedNfe
  def self.parse(bytes)
    xml = Nokogiri::XML(bytes) { |config| config.strict.noblanks }
    inf = xml.at_xpath("//*[local-name()='infNFe']")
    return if inf.nil?

    vnf = inf.at_xpath(".//*[local-name()='total']/*[local-name()='ICMSTot']/*[local-name()='vNF']")&.text
    payee = inf.at_xpath(".//*[local-name()='emit']/*[local-name()='xNome']")&.text&.strip
    dhemi = inf.at_xpath(".//*[local-name()='ide']/*[local-name()='dhEmi']")&.text
    id = inf["Id"].to_s
    amount_cents = BrlCents.parse(vnf)
    document_on = calendar_date(dhemi)
    chave = id.delete_prefix("NFe")
    return if amount_cents.nil? || amount_cents == 0 || payee.blank? || document_on.nil? || chave.blank?

    new(amount_cents:, document_on:, payee:, chave:)
  rescue Nokogiri::XML::SyntaxError
    nil
  end

  def self.calendar_date(dhemi)
    Date.iso8601(dhemi.to_s[0, 10])
  rescue ArgumentError, Date::Error
    nil
  end
  private_class_method :calendar_date

  attr_reader :amount_cents, :document_on, :payee, :chave

  def initialize(amount_cents:, document_on:, payee:, chave:)
    @amount_cents = amount_cents
    @document_on = document_on
    @payee = payee
    @chave = chave
  end
end
