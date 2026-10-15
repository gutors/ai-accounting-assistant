class Suggestion
  RANK = { equal: 0, format_2: 1, greater: 2, lesser: 3 }.freeze

  attr_reader :payments, :supporting_documents

  def initialize(payments:, supporting_documents:)
    @payments = Array(payments)
    @supporting_documents = Array(supporting_documents)
  end

  def self.assign(organization)
    Assigner.new(organization).proposals
  end

  def self.format_2_for_n1_form(proposals)
    Array(proposals)
      .uniq { |proposal| proposal.payments.map(&:id).sort }
      .select { |proposal| proposal.payments.size == 2 }
      .min_by { |proposal| proposal.payments.map(&:id).min }
  end

  def covers_payment?(payment)
    payments.any? { |member| member.id == payment.id }
  end

  def suggested_document?(document)
    supporting_documents.any? { |member| member.id == document.id }
  end

  def one_to_one_form_document_ids
    return [] unless payments.size == 1

    supporting_documents.map(&:id)
  end

  def self.next_one_payment(payments, proposals_by_payment_id)
    Array(payments).find do |payment|
      next false unless payment.missing_document?

      proposal = proposals_by_payment_id[payment.id]
      proposal&.payments&.size == 1
    end
  end

  def self.name_hit?(payee, history)
    left = normalize_name(payee)
    right = normalize_name(history)
    left.present? && right.present? && (right.include?(left) || left.include?(right))
  end

  def self.normalize_name(value)
    ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/\s+/, " ").strip
  end

  class Assigner
    Candidate = Struct.new(:rank, :name_hit, :payments, :documents, :tie_id, keyword_init: true)

    def initialize(organization)
      @organization = organization
    end

    def proposals
      taken_payments = {}
      taken_documents = {}
      chosen = []

      sorted_candidates.each do |candidate|
        payment_ids = candidate.payments.map(&:id)
        document_ids = candidate.documents.map(&:id)
        next if payment_ids.any? { |id| taken_payments[id] }
        next if document_ids.any? { |id| taken_documents[id] }

        payment_ids.each { |id| taken_payments[id] = true }
        document_ids.each { |id| taken_documents[id] = true }
        chosen << Suggestion.new(
          payments: candidate.payments.sort_by(&:id),
          supporting_documents: candidate.documents.sort_by(&:id)
        )
      end

      chosen
    end

    private

    def sorted_candidates
      candidates.sort_by do |candidate|
        [
          Suggestion::RANK.fetch(candidate.rank),
          candidate.name_hit ? 0 : 1,
          candidate.payments.map(&:id).min,
          candidate.tie_id
        ]
      end
    end

    def candidates
      groups.flat_map { |group| candidates_for(group) }
    end

    def candidates_for(group)
      amount_key = group.fetch(:amount_cents)
      documents = group.fetch(:documents)
      built = []

      missing_payments.each do |payment|
        next unless documents_compatible?(documents, payment)

        if payment.amount_cents == amount_key
          built << candidate(:equal, [ payment ], documents, group[:tie_id])
        elsif payment.amount_cents < amount_key
          built << candidate(:greater, [ payment ], documents, group[:tie_id])
        else
          built << candidate(:lesser, [ payment ], documents, group[:tie_id])
        end
      end

      if documents.size == 1
        missing_payments.group_by { |payment| payment.bank_statement.month_id }.each_value do |month_payments|
          month_payments.combination(2).each do |left, right|
            next unless documents_compatible?(documents, left)
            next unless left.amount_cents + right.amount_cents == amount_key

            built << candidate(:format_2, [ left, right ], documents, group[:tie_id])
          end
        end
      end

      built
    end

    def candidate(rank, payments, documents, tie_id)
      hit = payments.any? do |payment|
        documents.any? { |document| Suggestion.name_hit?(document.payee, payment.history) }
      end
      Candidate.new(rank: rank, name_hit: hit, payments: payments, documents: documents, tie_id: tie_id)
    end

    def documents_compatible?(documents, payment)
      documents.all? { |document| document.month_id.nil? || document.month_id == payment.bank_statement.month_id }
    end

    def groups
      unmatched = @organization.supporting_documents.unmatched.includes(:justification).order(:id).to_a
      grouped, loose = unmatched.partition(&:justification_id)

      justification_groups = grouped.group_by(&:justification_id).map do |_id, documents|
        justification = documents.first.justification
        {
          amount_cents: justification.amount_cents,
          documents: documents,
          tie_id: justification.id
        }
      end

      loose_groups = loose.map do |document|
        { amount_cents: document.amount_cents, documents: [ document ], tie_id: document.id }
      end

      justification_groups + loose_groups
    end

    def missing_payments
      @missing_payments ||= Payment.missing_document
        .joins(bank_statement: :month)
        .where(months: { organization_id: @organization.id, closed: false })
        .includes(bank_statement: :month)
        .order(:id)
        .to_a
    end
  end
  private_constant :Assigner
end
