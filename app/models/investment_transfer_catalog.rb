class InvestmentTransferCatalog
  ROWS = [
    { compe: "001", substring: "rende facil" }
  ].freeze

  def self.debit?(compe:, history:)
    haystack = I18n.transliterate(history.to_s).downcase
    ROWS.any? { |row| row[:compe] == compe.to_s && haystack.include?(row[:substring]) }
  end

  def self.payment?(payment)
    debit?(compe: payment.bank_statement.bank_account.bank.compe, history: payment.history)
  end

  def self.movement?(compe:, movement:)
    return false if movement.credit

    debit?(compe: compe, history: movement.history)
  end
end
