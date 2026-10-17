require "nokogiri"

class AuthorizedNfe
  ACCEPTED_INF = %w[infNFe infNFCom infNF3e infNFSe].freeze
  OTHER_DFE = %w[infCte infCteOS infMDFe infBPe infNFAg infNFGas CFe infCFe CompNfse InfNfse].freeze
  ID_PREFIXES = %w[NFCom NF3e NFe NFS].freeze

  def self.parse(bytes)
    xml = parse_document(bytes)
    return if xml.nil?

    inf, amount_cents = accepted_amount(xml)
    return if inf.nil?

    payee = inf.at_xpath(".//*[local-name()='emit']/*[local-name()='xNome']")&.text&.strip
    payee = inf.at_xpath(".//*[local-name()='prest']/*[local-name()='xNome']")&.text&.strip if payee.blank?
    dhemi = inf.at_xpath(".//*[local-name()='dhEmi']")&.text
    chave = strip_id_prefix(inf["Id"].to_s)
    document_on = calendar_date(dhemi)
    return if amount_cents.nil? || amount_cents == 0 || payee.blank? || document_on.nil? || chave.blank?

    new(amount_cents:, document_on:, payee:, chave:)
  end

  def self.unsupported?(bytes)
    xml = parse_document(bytes)
    return false if xml.nil?
    return false if ACCEPTED_INF.any? { |name| xml.at_xpath("//*[local-name()='#{name}']") }

    OTHER_DFE.any? { |name| xml.at_xpath("//*[local-name()='#{name}']") }
  end

  def self.parse_document(bytes)
    Nokogiri::XML(bytes) { |config| config.strict.noblanks }
  rescue Nokogiri::XML::SyntaxError
    nil
  end
  private_class_method :parse_document

  def self.accepted_amount(xml)
    inf_nfe = xml.at_xpath("//*[local-name()='infNFe']")
    if inf_nfe
      vnf = inf_nfe.at_xpath(".//*[local-name()='total']/*[local-name()='ICMSTot']/*[local-name()='vNF']")&.text
      return [ inf_nfe, BrlCents.parse(vnf) ]
    end

    inf_nfcom = xml.at_xpath("//*[local-name()='infNFCom']")
    if inf_nfcom
      vnf = inf_nfcom.at_xpath(".//*[local-name()='total']/*[local-name()='vNF']")&.text
      return [ inf_nfcom, BrlCents.parse(vnf) ]
    end

    inf_nf3e = xml.at_xpath("//*[local-name()='infNF3e']")
    if inf_nf3e
      vnf = inf_nf3e.at_xpath(".//*[local-name()='vNF']")&.text
      return [ inf_nf3e, BrlCents.parse(vnf) ]
    end

    inf_nfse = xml.at_xpath("//*[local-name()='infNFSe']")
    if inf_nfse
      vserv = inf_nfse.at_xpath(".//*[local-name()='vServ']")&.text
      return [ inf_nfse, BrlCents.parse(vserv) ]
    end

    [ nil, nil ]
  end
  private_class_method :accepted_amount

  def self.strip_id_prefix(id)
    ID_PREFIXES.each { |prefix| return id.delete_prefix(prefix) if id.start_with?(prefix) }
    id
  end
  private_class_method :strip_id_prefix

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
