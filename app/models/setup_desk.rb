class SetupDesk
  KEYS = %w[accountant archive certificate banks extras].freeze
  EDIT_ITEM = {
    "accountant" => "accountant",
    "package_archive" => "archive",
    "bank_account" => "banks"
  }.freeze
  TITLES = {
    "accountant" => "Contador",
    "archive" => "Arquivo do pacote",
    "certificate" => "Certificado A1",
    "banks" => "Contas bancárias",
    "extras" => "Tipos extras"
  }.freeze

  Row = Data.define(:key, :title, :href, :detail, :stamp, :blocked, :selected) do
    def blocked?
      blocked
    end

    def selected?
      selected
    end
  end

  def initialize(organization, bank_accounts:, extra_exception_kinds:, item: nil, edit: nil, forced_item: nil)
    @organization = organization
    @bank_accounts = bank_accounts
    @extra_exception_kinds = extra_exception_kinds
    @item = item.to_s
    @edit = edit.to_s
    @forced_item = forced_item.to_s
  end

  def selected
    @selected ||= select_item
  end

  def rows
    KEYS.map { |key| row_for(key) }
  end

  def incomplete?(key)
    case key
    when "accountant" then organization.accountant_presentation_name.blank?
    when "archive" then organization.package_archive_url.blank?
    when "certificate" then organization.sefaz_titular_cnpj.blank? || organization.sefaz_certificate_expired?
    when "banks" then bank_accounts.empty?
    when "extras" then false
    else false
    end
  end

  private

  attr_reader :organization, :bank_accounts, :extra_exception_kinds

  def select_item
    return @forced_item if KEYS.include?(@forced_item)
    return @item if KEYS.include?(@item)

    mapped = EDIT_ITEM[@edit]
    return mapped if mapped

    KEYS.find { |key| incomplete?(key) } || "accountant"
  end

  def row_for(key)
    blocked = incomplete?(key)
    Row.new(
      key: key,
      title: TITLES.fetch(key),
      href: "/setup?item=#{key}",
      detail: detail_for(key),
      stamp: stamp_for(key),
      blocked: blocked,
      selected: key == selected
    )
  end

  def detail_for(key)
    case key
    when "accountant" then organization.accountant_presentation_name.to_s
    when "archive" then "Pasta do Drive"
    when "certificate" then "Consulta SEFAZ"
    when "banks" then banks_detail
    when "extras" then extras_detail
    end
  end

  def banks_detail
    n = bank_accounts.size
    return if n.zero?

    n == 1 ? "1 conta" : "#{n} contas"
  end

  def extras_detail
    names = []
    names << "Tarifa" if organization.bank_fee_exception_active?
    names << "honorário" if organization.accountant_fee_exception_active?
    names.join(" e ")
  end

  def stamp_for(key)
    case key
    when "accountant" then incomplete?("accountant") ? "Falta" : "Cadastrado"
    when "archive" then incomplete?("archive") ? "Falta" : ""
    when "certificate" then certificate_stamp
    when "banks" then incomplete?("banks") ? "Falta" : "Ativas"
    when "extras" then extras_stamp
    end
  end

  def certificate_stamp
    return "Falta" if organization.sefaz_titular_cnpj.blank?
    return "Expirado" if organization.sefaz_certificate_expired?

    "Instalado"
  end

  def extras_stamp
    n = extra_active_count
    "#{n} #{n == 1 ? 'ativo' : 'ativos'}"
  end

  def extra_active_count
    n = 0
    n += 1 if organization.bank_fee_exception_active?
    n += 1 if organization.accountant_fee_exception_active?
    n + extra_exception_kinds.count(&:active?)
  end
end
