require "rails_helper"

RSpec.describe ExtraExceptionKind, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  it "create Doacao persists active ExtraExceptionKind" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    expect(kind).to be_persisted
    expect(kind).to be_active
    expect(kind.name).to eq("Doação")
    expect(kind.organization).to eq(organization)
  end

  it "create trims Doacao" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "  Doação  ")

    expect(kind).to be_persisted
    expect(kind.name).to eq("Doação")
  end

  it "same name on another organization persists" do
    other = Organization.create!(name: "Outra")
    ExtraExceptionKind.create_for(organization: other, name: "Doação")

    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    expect(kind).to be_persisted
    expect(other.extra_exception_kinds.where(name: "Doação").count).to eq(1)
    expect(organization.extra_exception_kinds.where(name: "Doação").count).to eq(1)
  end

  it "rejects duplicate Doacao" do
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    duplicate = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    expect(duplicate).not_to be_persisted
    expect(organization.extra_exception_kinds.where(name: "Doação").count).to eq(1)
  end

  it "rejects doacao when Doacao exists" do
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    duplicate = ExtraExceptionKind.create_for(organization: organization, name: "doação")

    expect(duplicate).not_to be_persisted
    expect(organization.extra_exception_kinds.count).to eq(1)
  end

  it "rejects Tarifa bancaria" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Tarifa bancária")

    expect(kind).not_to be_persisted
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "rejects honorario do contador" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "honorário do contador")

    expect(kind).not_to be_persisted
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "rejects blank name" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "   ")

    expect(kind).not_to be_persisted
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "deactivate keeps the row" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    expect(kind.apply_active(false)).to be(true)
    expect(kind.reload).not_to be_active
    expect(ExtraExceptionKind.find(kind.id).name).to eq("Doação")
  end

  it "reactivate sets active" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    kind.apply_active(false)

    expect(kind.apply_active(true)).to be(true)
    expect(kind.reload).to be_active
  end

  it "destroy unused Folha deletes the row" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Folha")

    expect(kind.destroy_if_unused).to be(true)
    expect(ExtraExceptionKind.find_by(id: kind.id)).to be_nil
  end

  it "destroy used Doacao is rejected" do
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    payment.update!(extra_exception_kind: kind)

    expect(kind.destroy_if_unused).to be(false)
    expect(ExtraExceptionKind.find(kind.id)).to eq(kind)
    expect(payment.reload.extra_exception_kind_id).to eq(kind.id)
  end

  it "rejects Doacao while deactivated Doacao exists" do
    existing = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    existing.apply_active(false)

    duplicate = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    expect(duplicate).not_to be_persisted
    expect(existing.reload).not_to be_active
    expect(organization.extra_exception_kinds.count).to eq(1)
  end

  describe "concurrent creates persist exactly one ExtraExceptionKind" do
    self.use_transactional_tests = false

    it "concurrent creates persist exactly one ExtraExceptionKind" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")

      run_in_parallel(2) do
        ExtraExceptionKind.create_for(organization: org, name: "Doação")
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(ExtraExceptionKind.where(organization: org, name: "Doação").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end

  describe "concurrent unused destroy and mark persist kind plus mark or neither" do
    self.use_transactional_tests = false

    it "concurrent unused destroy and mark persist kind plus mark or neither" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")
      kind = ExtraExceptionKind.create_for(organization: org, name: "Folha")
      _month, statement = plant_month(org)
      payment = plant_payment(statement, 22000)
      queue = Queue.new
      queue << :destroy
      queue << :mark

      run_in_parallel(2) do
        action = queue.pop
        if action == :destroy
          ExtraExceptionKind.find(kind.id).destroy_if_unused
        else
          payment.mark_document_exception(extra_exception_kind_id: kind.id)
        end
      rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed,
             ActiveRecord::DeleteRestrictionError, ActiveRecord::StatementInvalid
        nil
      end

      remaining = ExtraExceptionKind.find_by(id: kind.id)
      marked_id = payment.reload.extra_exception_kind_id
      expect(remaining.present?).to eq(marked_id.present?)
      expect(ExtraExceptionKind.find_by(id: marked_id)).to be_present if marked_id
    ensure
      truncate_product_tables
    end
  end
end
