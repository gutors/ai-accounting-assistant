class ExceptionSuggestion
  KIND = "accountant_fee".freeze

  attr_reader :payment, :kind

  def initialize(payment:)
    @payment = payment
    @kind = KIND
  end

  def self.assign(organization, match_proposals: nil)
    Assigner.new(organization, match_proposals: match_proposals).proposals
  end

  class Assigner
    def initialize(organization, match_proposals:)
      @organization = organization
      @given_match_proposals = match_proposals
    end

    def proposals
      return [] unless pix_key.present? || tax_id.present?

      covered = covered_payment_ids
      missing_payments.filter_map do |payment|
        next if covered[payment.id]
        next unless hit?(payment.history)

        ExceptionSuggestion.new(payment: payment)
      end
    end

    private

    def match_proposals
      return @given_match_proposals unless @given_match_proposals.nil?

      Suggestion.assign(@organization)
    end

    def covered_payment_ids
      match_proposals.each_with_object({}) do |proposal, index|
        proposal.payments.each { |payment| index[payment.id] = true }
      end
    end

    def missing_payments
      Payment.missing_document
        .joins(bank_statement: :month)
        .where(months: { organization_id: @organization.id, closed: false })
        .includes(bank_statement: :month)
        .order(:id)
        .to_a
    end

    def hit?(history)
      pix_hit?(history) || tax_id_hit?(history)
    end

    def pix_key
      @organization.accountant_pix_key
    end

    def tax_id
      @organization.accountant_tax_id
    end

    def pix_hit?(history)
      trimmed = pix_key.to_s.strip
      return false if trimmed.blank?

      if NormalizedEmail.valid?(trimmed)
        history.to_s.downcase.include?(trimmed.downcase)
      elsif trimmed.match?(/\d/)
        digits(history).include?(digits(trimmed))
      else
        history.to_s.downcase.include?(trimmed.downcase)
      end
    end

    def tax_id_hit?(history)
      normalized = BrazilianTaxId.normalize(tax_id)
      return false if normalized.blank?

      digits(history).include?(normalized)
    end

    def digits(value)
      value.to_s.gsub(/\D/, "")
    end
  end
  private_constant :Assigner
end
