require "rails_helper"

RSpec.describe Suggestion, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-coord")
  end

  def month_and_statement(year_month = "2026-05")
    @months ||= {}
    @months[year_month] ||= plant_month(organization, year_month: year_month)
  end

  def statement(year_month = "2026-05")
    month_and_statement(year_month)[1]
  end

  def proposals
    described_class.assign(organization)
  end

  def proposal_for(payment)
    proposals.find { |proposal| proposal.payments.map(&:id).include?(payment.id) }
  end

  it "equal 1:1 name hit assigns Padaria Central" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    proposal = proposal_for(payment)

    expect(proposal).to be_present
    expect(proposal.payments.map(&:id)).to eq([ payment.id ])
    expect(proposal.supporting_documents.map(&:id)).to eq([ document.id ])
  end

  it "assign does not persist a Match" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    described_class.assign(organization)

    expect(Match.count).to eq(0)
    expect(payment.reload.match_id).to be_nil
    expect(payment.document_exception_kind).to be_nil
    expect(payment.extra_exception_kind_id).to be_nil
    expect(document.reload.month_id).to be_nil
    expect(document.match_id).to be_nil
  end

  it "no unmatched document assigns nothing" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")

    expect(proposal_for(payment)).to be_nil
    expect(proposals).to be_empty
  end

  it "recibo equal 1:1 is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.kind).to eq("recibo")
  end

  it "nota_fiscal equal 1:1 is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_nota(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.kind).to eq("nota_fiscal")
    expect(document.xml).to be_attached
  end

  it "document inserted after payment is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    expect(proposal_for(payment)).to be_nil

    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
  end

  it "equal rank name hit beats no name hit" do
    padaria = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    mercado = plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(padaria).supporting_documents).to eq([ document ])
    expect(proposal_for(mercado)).to be_nil
  end

  it "equal name-hit tie breaks on lowest payment id" do
    first = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    second = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(first.id).to be < second.id
    expect(proposal_for(first).supporting_documents).to eq([ document ])
    expect(proposal_for(second)).to be_nil
  end

  it "equal two docs name hit picks Padaria Central" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    proposal = proposal_for(payment)
    expect(proposal.supporting_documents).to eq([ padaria ])
    expect(proposal.supporting_documents).not_to include(mercado)
  end

  it "equal no-name-hit tie breaks on lowest document id" do
    payment = plant_payment(statement, 22000, history: "Pix")
    norte = plant_recibo(organization, account, payee: "Padaria Norte", amount: "220,00")
    sul = plant_recibo(organization, account, payee: "Padaria Sul", amount: "220,00")

    expect(norte.id).to be < sul.id
    expect(proposal_for(payment).supporting_documents).to eq([ norte ])
  end

  it "open-month name hit assigns May payment not June" do
    may = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    june = plant_payment(statement("2026-06"), 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(may).supporting_documents).to eq([ document ])
    expect(proposal_for(june)).to be_nil
  end

  it "cross-month equal tie breaks on lowest payment id" do
    may = plant_payment(statement, 22000, history: "Pix")
    june = plant_payment(statement("2026-06"), 22000, history: "Pix")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    lower = [ may, june ].min_by(&:id)
    other = [ may, june ].find { |payment| payment.id != lower.id }

    expect(proposal_for(lower).supporting_documents).to eq([ document ])
    expect(proposal_for(other)).to be_nil
  end

  it "document_on before occurred_on is still assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 20))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-04-30")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.document_on).to eq(Date.new(2026, 4, 30))
  end

  it "equal with no name hit still assigns" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Outro")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
  end

  it "name hit folds Jose to JOSE" do
    jose = plant_payment(statement, 22000, history: "Pix enviado — JOSE SILVA")
    mercado = plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "José Silva", amount: "220,00")

    expect(proposal_for(jose).supporting_documents).to eq([ document ])
    expect(proposal_for(mercado)).to be_nil
  end

  it "a Payment belongs to at most one suggestion" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    expect(proposals.count { |proposal| proposal.payments.map(&:id).include?(payment.id) }).to eq(1)
  end

  it "a SupportingDocument belongs to at most one suggestion" do
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposals.count { |proposal| proposal.supporting_documents.map(&:id).include?(document.id) }).to eq(1)
  end

  it "equal rank beats greater rank" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "250,00")

    expect(proposal_for(payment).supporting_documents).to eq([ padaria ])
  end

  it "greater rank beats lesser rank" do
    payment = plant_payment(statement, 22000)
    greater = plant_recibo(organization, account, payee: "Padaria Grande", amount: "250,00")
    plant_recibo(organization, account, payee: "Padaria Pequena", amount: "200,00")

    expect(proposal_for(payment).supporting_documents).to eq([ greater ])
  end

  it "lesser 1:1 is assigned" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
  end

  it "format-2 assigns both payments and one document" do
    ten = plant_payment(statement, 10000)
    twelve = plant_payment(statement, 12000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    assigned = proposals
    ten_proposal = assigned.find { |proposal| proposal.payments.map(&:id).include?(ten.id) }
    twelve_proposal = assigned.find { |proposal| proposal.payments.map(&:id).include?(twelve.id) }

    expect(ten_proposal.payments.map(&:id)).to contain_exactly(ten.id, twelve.id)
    expect(twelve_proposal.payments.map(&:id)).to contain_exactly(ten.id, twelve.id)
    expect(ten_proposal.supporting_documents).to eq([ document ])
    expect(twelve_proposal.supporting_documents).to eq([ document ])
  end

  it "equal rank beats format-2 rank" do
    equal = plant_payment(statement, 22000)
    ten = plant_payment(statement, 10000)
    plant_payment(statement, 12000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(equal).supporting_documents).to eq([ document ])
    expect(proposal_for(ten)).to be_nil
  end

  it "format-2 name hit beats format-2 no name hit" do
    padaria_ten = plant_payment(statement, 10000, history: "Pix enviado — Padaria Central")
    padaria_twelve = plant_payment(statement, 12000, history: "Pix enviado — Padaria Central")
    outro_ten = plant_payment(statement, 10000, history: "Outro")
    outro_twelve = plant_payment(statement, 12000, history: "Outro")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(padaria_ten).supporting_documents).to eq([ document ])
    expect(proposal_for(padaria_twelve).supporting_documents).to eq([ document ])
    expect(proposal_for(outro_ten)).to be_nil
    expect(proposal_for(outro_twelve)).to be_nil
  end

  it "suggestion shape is 1:N or exactly 2:1" do
    plant_payment(statement, 22000, history: "Pix A")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_payment(statement, 10000, history: "Pix B")
    plant_payment(statement, 15000, history: "Pix B")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "250,00")

    expect(proposals).not_to be_empty
    proposals.each do |proposal|
      one_to_many = proposal.payments.size == 1 && proposal.supporting_documents.size >= 1
      two_to_one = proposal.payments.size == 2 && proposal.supporting_documents.size == 1
      expect(one_to_many || two_to_one).to be(true)
    end
  end

  it "does not assign three payments to one document" do
    plant_payment(statement, 7000)
    plant_payment(statement, 7000)
    plant_payment(statement, 8000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    matching = proposals.select { |proposal| proposal.supporting_documents.map(&:id).include?(document.id) }
    expect(matching).to all(satisfy { |proposal| proposal.payments.size < 3 })
  end

  def cover(amount, documents)
    Justification.declare(
      organization: organization,
      account: account,
      amount: amount,
      supporting_document_ids: documents.map(&:id)
    )
  end

  it "justification equal assigns all members" do
    payment = plant_payment(statement, 20000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover("200,00", [ padaria, mercado ])

    expect(proposal_for(payment).supporting_documents.map(&:id)).to contain_exactly(padaria.id, mercado.id)
  end

  it "justification members are never assigned as individuals" do
    equal = plant_payment(statement, 20000, history: "Pix enviado — Igual")
    member = plant_payment(statement, 15500, history: "Pix enviado — Membro")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover("200,00", [ padaria, mercado ])

    expect(proposal_for(equal).supporting_documents.map(&:payee)).to include("Padaria Central")
    expect(proposal_for(member)).to be_nil
  end

  it "multi-document justification never takes format-2" do
    ten_a = plant_payment(statement, 10000, history: "Pix enviado — A")
    ten_b = plant_payment(statement, 10000, history: "Pix enviado — B")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover("200,00", [ padaria, mercado ])

    two_and_two = proposals.find do |proposal|
      proposal.payments.size == 2 && proposal.supporting_documents.size == 2
    end
    expect(two_and_two).to be_nil
    together = proposals.find do |proposal|
      proposal.payments.map(&:id).sort == [ ten_a.id, ten_b.id ].sort &&
        proposal.supporting_documents.map(&:id).sort == [ padaria.id, mercado.id ].sort
    end
    expect(together).to be_nil
  end

  it "justification amount_cents is the equal key" do
    payment = plant_payment(statement, 18000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover("180,00", [ padaria, mercado ])

    expect(proposal_for(payment).supporting_documents.map(&:id)).to contain_exactly(padaria.id, mercado.id)
  end

  it "justification 22000 equal assigns members summing 20000" do
    payment = plant_payment(statement, 22000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover("220,00", [ padaria, mercado ])

    expect(proposal_for(payment).supporting_documents.map(&:id)).to contain_exactly(padaria.id, mercado.id)
  end

  it "does not assign another organization document" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Mesmo valor")
    other = Organization.create!(name: "B")
    other_account = Account.create!(email: "b@example.com", google_uid: "uid-b")
    document = plant_recibo(other, other_account, payee: "Padaria Beta Isolada", amount: "220,00")

    expect(proposal_for(payment)).to be_nil
    expect(proposals.flat_map(&:supporting_documents)).not_to include(document)
  end

  it "closed month payments are not assigned" do
    month, month_statement = plant_month(organization)
    payment = plant_payment(month_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    month.update!(closed: true)

    expect(proposal_for(payment)).to be_nil
  end

  it "format_2_for_n1_form returns the two-payment proposal" do
    ten = plant_payment(statement, 10000)
    twelve = plant_payment(statement, 12000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    proposal = described_class.new(payments: [ ten, twelve ], supporting_documents: [ document ])

    expect(described_class.format_2_for_n1_form([ proposal ])).to eq(proposal)
  end

  it "two format-2 proposals n1 form picks lowest payment id" do
    ten = plant_payment(statement, 10000)
    twelve = plant_payment(statement, 12000)
    fourteen = plant_payment(statement, 14000)
    sixteen = plant_payment(statement, 16000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "300,00")
    padaria_pair = described_class.new(payments: [ ten, twelve ], supporting_documents: [ padaria ])
    mercado_pair = described_class.new(payments: [ fourteen, sixteen ], supporting_documents: [ mercado ])

    expect(ten.id).to be < fourteen.id
    expect(described_class.format_2_for_n1_form([ mercado_pair, padaria_pair ])).to eq(padaria_pair)
  end
end
