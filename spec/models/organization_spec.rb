require "rails_helper"

RSpec.describe Organization, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it "persists trimmed accountant presentation name" do
    organization = create_organization!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "  Ana Contábil  ")).to be(true)
    expect(organization.accountant_presentation_name).to eq("Ana Contábil")
  end

  it "persists CNPJ digits and razao social" do
    organization = create_organization!(name: "ONG")

    expect(organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "11.222.333/0001-81",
      legal_name: "  Contábil LTDA  "
    )).to be(true)
    expect(organization.accountant_tax_id).to eq("11222333000181")
    expect(organization.accountant_legal_name).to eq("Contábil LTDA")
  end

  it "persists CPF digits and no razao social" do
    organization = create_organization!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", tax_id: "390.533.447-05")).to be(true)
    expect(organization.accountant_tax_id).to eq("39053344705")
    expect(organization.accountant_legal_name).to be_nil
  end

  it "persists destination email via NormalizedEmail" do
    organization = create_organization!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", destination_email: "Coord@Example.COM")).to be(true)
    expect(organization.package_destination_email).to eq("coord@example.com")
  end

  it "persists PIX of 1 and 77 characters" do
    organization = create_organization!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", pix_key: "x")).to be(true)
    expect(organization.accountant_pix_key).to eq("x")

    seventy_seven = "p" * 77
    expect(organization.update_accountant(presentation_name: "Ana", pix_key: seventy_seven)).to be(true)
    expect(organization.accountant_pix_key).to eq(seventy_seven)
  end

  it "blank optional accountant fields clear them" do
    organization = create_organization!(name: "ONG")
    organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "11.222.333/0001-81",
      legal_name: "Contábil LTDA",
      pix_key: "chave",
      destination_email: "ana@example.com"
    )

    expect(organization.update_accountant(presentation_name: "Ana")).to be(true)
    expect(organization.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
    expect(organization.accountant_pix_key).to be_nil
    expect(organization.package_destination_email).to be_nil
  end

  it "rejects satellite accountant fields without presentation name" do
    [
      { tax_id: "39053344705" },
      { legal_name: "Contábil LTDA" },
      { pix_key: "x" },
      { destination_email: "ana@example.com" }
    ].each_with_index do |attrs, index|
      organization = create_organization!(name: "ONG #{index}")
      expect(organization.update_accountant(attrs)).to be(false)
      organization.reload
      expect(organization.accountant_tax_id).to be_nil
      expect(organization.accountant_legal_name).to be_nil
      expect(organization.accountant_pix_key).to be_nil
      expect(organization.package_destination_email).to be_nil
    end
  end

  it "rejects tax id length and check digits" do
    organization = create_organization!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    [
      "1234567890",
      "39053344700",
      "11222333000180"
    ].each do |tax_id|
      expect(organization.update_accountant(presentation_name: "Ana", tax_id: tax_id)).to be(false)
      expect(organization.reload.accountant_tax_id).to be_nil
    end
  end

  it "rejects CNPJ without razao social adds Informe a razao social" do
    organization = create_organization!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    expect(organization.update_accountant(presentation_name: "Ana", tax_id: "11222333000181")).to be(false)
    expect(organization.errors[:base]).to include("Informe a razão social")
    expect(organization.reload.accountant_tax_id).to be_nil
  end

  it "rejects CPF with razao social" do
    organization = create_organization!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    expect(organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "39053344705",
      legal_name: "Não deveria"
    )).to be(false)
    expect(organization.reload.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
  end

  it "rejects destination that fails NormalizedEmail" do
    organization = create_organization!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana", destination_email: "ana@example.com")

    expect(organization.update_accountant(presentation_name: "Ana", destination_email: "not-an-email")).to be(false)
    expect(organization.reload.package_destination_email).to eq("ana@example.com")
  end

  it "persists Drive folders URL and extracted folder id" do
    organization = create_organization!(name: "ONG")
    url = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"

    expect(organization.update_package_archive(url)).to be(true)
    expect(organization.package_archive_url).to eq(url)
    expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
  end

  it "extracts folder id from drive/u/0/folders URL with query" do
    organization = create_organization!(name: "ONG")
    url = "https://drive.google.com/drive/u/0/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl?usp=sharing"

    expect(organization.update_package_archive(url)).to be(true)
    expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
  end

  it "blank archive URL clears url and folder id" do
    organization = create_organization!(name: "ONG")
    organization.update_package_archive("https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")

    expect(organization.update_package_archive("")).to be(true)
    expect(organization.package_archive_url).to be_nil
    expect(organization.package_archive_folder_id).to be_nil
  end

  it "rejects http, wrong host, and missing folders segment" do
    organization = create_organization!(name: "ONG")
    good = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    organization.update_package_archive(good)

    [
      "http://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://drive.google.com/drive/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    ].each do |url|
      expect(organization.update_package_archive(url)).to be(false)
      organization.reload
      expect(organization.package_archive_url).to eq(good)
      expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
    end
  end

  it "rejects Drive file URL" do
    organization = create_organization!(name: "ONG")
    good = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    organization.update_package_archive(good)

    expect(organization.update_package_archive("https://drive.google.com/file/d/0B_NiLAzvehC9R2stRmQyM3ZiVjQ/view")).to be(false)
    organization.reload
    expect(organization.package_archive_url).to eq(good)
  end

  it "install pfx persists titular 11222333000181 and notAfter 2027-09-18" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
    expect(organization.sefaz_not_after).to eq(Date.new(2027, 9, 18))
    pkcs12 = organization.unwrap_sefaz_pkcs12
    expect(pkcs12).to be_a(OpenSSL::PKCS12)
  end

  it "install p12 persists titular 11222333000181" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_p12, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
  end

  it "sefaz pkcs12 exposure is nil without titular" do
    organization = create_organization!(name: "ONG")

    expect(organization.sefaz_pkcs12).to be_nil
  end

  it "sefaz pkcs12 exposure is nil when expired" do
    organization = create_organization!(name: "ONG")
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
    travel_to Date.new(2026, 5, 12) do
      expect(organization.sefaz_pkcs12).to be_nil
    end
  end

  it "sefaz pkcs12 exposure is nil on unwrap miss" do
    organization = create_organization!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    with_env("SEFAZ_WRAP_KEY" => nil) do
      expect(organization.sefaz_pkcs12).to be_nil
    end
  end

  it "sefaz pkcs12 exposure returns PKCS12 for a valid A1" do
    organization = create_organization!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    expect(organization.sefaz_pkcs12).to be_a(OpenSSL::PKCS12)
  end

  it "install with passphrase errada persists no certificate" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "errada")).to be(false)
    expect(organization.errors[:base]).to include("Não foi possível abrir o certificado com essa senha")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install e-CPF 39053344705 persists no certificate" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: sefaz_pfx(titular: "39053344705"),
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install notAfter 2026-05-10 on 2026-05-11 persists no certificate" do
    organization = create_organization!(name: "ONG")

    travel_to Date.new(2026, 5, 11) do
      expect(organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 10)),
        passphrase: "passphrase-secreta"
      )).to be(false)
    end
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install txt persists no certificate" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: sefaz_txt_certificate,
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install larger than 1048576 persists no certificate" do
    organization = create_organization!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: oversized_sefaz_pfx,
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install second A1 replaces titular 12345678000101" do
    organization = create_organization!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    expect(organization.install_sefaz_certificate(
      file: sefaz_pfx(titular: "12345678000101", passphrase: "outrasenha", name: "other.pfx"),
      passphrase: "outrasenha"
    )).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("12345678000101")
    expect(organization.sefaz_titular_cnpj).not_to eq("11222333000181")
    pkcs12 = organization.unwrap_sefaz_pkcs12
    expect(pkcs12).to be_a(OpenSSL::PKCS12)
  end

  it "remove_sefaz_certificate nulls the slot" do
    organization = create_organization!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    organization.remove_sefaz_certificate

    expect(organization.sefaz_titular_cnpj).to be_nil
    expect(organization.sefaz_not_after).to be_nil
    expect(organization.sefaz_pkcs12_ciphertext).to be_nil
    expect(organization.sefaz_passphrase_ciphertext).to be_nil
  end

  it "install with blank wrap key persists no certificate" do
    organization = create_organization!(name: "ONG")

    with_env("SEFAZ_WRAP_KEY" => nil) do
      expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(false)
    end
    expect(organization.errors[:base]).to include("O certificado não pôde ser guardado")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install while a month is closed still persists" do
    organization = create_organization!(name: "ONG")
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
  end

  describe "concurrent A1 installs leave one consistent pair" do
    self.use_transactional_tests = false

    it "concurrent A1 installs leave one consistent pair" do
      truncate_product_tables
      organization = create_organization!(name: "ONG")
      first = sefaz_pfx(titular: "11222333000181", passphrase: "senha-a", name: "a.pfx")
      second = sefaz_pfx(titular: "12345678000101", passphrase: "senha-b", name: "b.pfx")
      queue = Queue.new
      queue << [ first, "senha-a" ]
      queue << [ second, "senha-b" ]

      run_in_parallel(2) do
        file, passphrase = queue.pop
        Organization.find(organization.id).install_sefaz_certificate(file:, passphrase:)
      end

      organization.reload
      expect(Organization.where(id: organization.id).where.not(sefaz_titular_cnpj: nil).count).to eq(1)
      expect(%w[11222333000181 12345678000101]).to include(organization.sefaz_titular_cnpj)
      expect(organization.unwrap_sefaz_pkcs12).to be_a(OpenSSL::PKCS12)
    ensure
      truncate_product_tables
    end
  end

  it "coordinator_emails are ordered by accounts.email and omit submitters" do
    organization = create_organization!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    ana = Account.create!(email: "ana@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: organization, kind: :coordinator)
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    Access.create!(account: submitter, organization: organization, kind: :submitter)
    organization.reload

    expect(organization.coordinator_emails).to eq([ "zoe@exemplo.org", "ana@exemplo.org" ])
    expect(organization.listed_coordinator_account.email).to eq("zoe@exemplo.org")
    expect(organization.listed_coordinator_signed_in?).to be(false)
  end

  it "listed_coordinator_signed_in? is true when the first coordinator has a google_uid" do
    organization = create_organization!(name: "ONG Norte")
    signed_in = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: signed_in, organization: organization, kind: :coordinator)
    organization.reload

    expect(organization.listed_coordinator_signed_in?).to be(true)
  end

  it "name_taken? ignores the organization being corrected" do
    norte = create_organization!(name: "ONG Norte")
    create_organization!(name: "ONG Sul")

    expect(Organization.name_taken?("ong sul", except: norte)).to be(true)
    expect(Organization.name_taken?("ong norte", except: norte)).to be(false)
  end

  it "updating onto a taken lower name raises RecordNotUnique and keeps the previous name" do
    norte = create_organization!(name: "ONG Norte")
    sul = create_organization!(name: "ONG Sul")

    expect {
      norte.update!(name: "ong sul")
    }.to raise_error(ActiveRecord::RecordNotUnique)

    expect(norte.reload.name).to eq("ONG Norte")
    expect(sul.reload.name).to eq("ONG Sul")
  end

  it "register_coordinator creates Organization Account and coordinator Access" do
    expect {
      organization = Organization.register_coordinator(name: "  ONG Norte  ", email: " Coordenador@Exemplo.ORG ")

      expect(organization.name).to eq("ONG Norte")
      account = Account.find_by!(email: "coordenador@exemplo.org")
      access = organization.accesses.find_by!(account: account)
      expect(access.kind).to eq("coordinator")
      expect(Invite.where(email: "coordenador@exemplo.org")).to be_empty
    }.to change(Organization, :count).by(1)
      .and change(Account, :count).by(1)
      .and change(Access, :count).by(1)
      .and change { ActionMailer::Base.deliveries.size }.by(0)
  end

  it "register_coordinator reuses an existing Account" do
    Account.create!(email: "coordenador@exemplo.org")

    expect {
      organization = Organization.register_coordinator(name: "ONG Norte", email: "coordenador@exemplo.org")
      account = Account.find_by!(email: "coordenador@exemplo.org")

      expect(organization.accesses.find_by!(account: account).kind).to eq("coordinator")
      expect(Invite.count).to eq(0)
    }.to change(Organization, :count).by(1)
      .and change(Account, :count).by(0)
      .and change(Access, :count).by(1)
      .and change { ActionMailer::Base.deliveries.size }.by(0)
  end

  it "register_coordinator rolls back when it raises before commit" do
    expect {
      Organization.register_coordinator(name: "ONG Sul", email: "nao-e-email")
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(Organization.find_by(name: "ONG Sul")).to be_nil
    expect(Account.count).to eq(0)
    expect(Access.count).to eq(0)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "register_coordinator rejects a name that differs only by case" do
    create_organization!(name: "ONG Norte")
    counts = [ Organization.count, Account.count, Access.count ]
    deliveries = ActionMailer::Base.deliveries.size

    [ "ONG Norte", "ong norte" ].each do |name|
      expect {
        Organization.register_coordinator(name: name, email: "outro#{name.length}@exemplo.org")
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    expect([ Organization.count, Account.count, Access.count ]).to eq(counts)
    expect(ActionMailer::Base.deliveries.size).to eq(deliveries)
    expect(Account.where("email LIKE ?", "outro%@exemplo.org")).to be_empty
  end

  it "register_coordinator rejects a padded uppercase name" do
    create_organization!(name: "ONG Norte")
    counts = [ Organization.count, Account.count, Access.count ]
    deliveries = ActionMailer::Base.deliveries.size

    expect {
      Organization.register_coordinator(name: "  ONG NORTE  ", email: "outro@exemplo.org")
    }.to raise_error(ActiveRecord::RecordNotUnique)

    expect([ Organization.count, Account.count, Access.count ]).to eq(counts)
    expect(ActionMailer::Base.deliveries.size).to eq(deliveries)
    expect(Account.find_by(email: "outro@exemplo.org")).to be_nil
  end

  it "replace_coordinator keeps the Access when the email is unchanged" do
    organization = create_organization!(name: "ONG Norte")
    account = Account.create!(email: "coordenador@exemplo.org")
    access = Access.create!(account: account, organization: organization, kind: :coordinator)

    expect {
      result = organization.replace_coordinator(access: access, email: " Coordenador@Exemplo.ORG ")
      expect(result.account).to eq(account)
      expect(result.created_account).to be(false)
    }.not_to change(Access, :count)

    expect(account.reload.email).to eq("coordenador@exemplo.org")
    expect(organization.accesses.coordinator.find_by!(account: account)).to eq(access)
  end

  it "replace_coordinator inserts the new Access then destroys the old and deletes the matching Invite" do
    norte = create_organization!(name: "ONG Norte")
    sul = create_organization!(name: "ONG Sul")
    old = Account.create!(email: "coordenador@exemplo.org")
    access = Access.create!(account: old, organization: norte, kind: :coordinator)
    Invite.create!(organization: norte, email: "novo@exemplo.org", kind: :coordinator)
    Invite.create!(organization: sul, email: "novo@exemplo.org", kind: :coordinator)

    expect {
      result = norte.replace_coordinator(access: access, email: " Novo@Exemplo.ORG ")
      expect(result.created_account).to be(true)
    }.to change(Account, :count).by(1)

    expect(old.reload.email).to eq("coordenador@exemplo.org")
    expect(norte.accesses.coordinator.count).to eq(1)
    expect(norte.accesses.coordinator.first.account.email).to eq("novo@exemplo.org")
    expect(norte.reload.principal_coordinator_account.email).to eq("novo@exemplo.org")
    expect(Invite.find_by(organization: norte, email: "novo@exemplo.org")).to be_nil
    expect(Invite.find_by(organization: sul, email: "novo@exemplo.org")).to be_present
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "replace_coordinator reuses an existing Account" do
    sul_account = Account.create!(email: "sul@exemplo.org")
    sul = create_organization!(name: "ONG Sul")
    Access.create!(account: sul_account, organization: sul, kind: :coordinator)
    norte = create_organization!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    access = Access.create!(account: old, organization: norte, kind: :coordinator)

    expect {
      result = norte.replace_coordinator(access: access, email: "sul@exemplo.org")
      expect(result.created_account).to be(false)
      expect(result.account).to eq(sul_account)
    }.not_to change(Account, :count)

    expect(old.reload.email).to eq("coordenador@exemplo.org")
    expect(norte.accesses.coordinator.first.account).to eq(sul_account)
    expect(norte.reload.principal_coordinator_account).to eq(sul_account)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "replace_coordinator rolls back when the write raises before commit" do
    norte = create_organization!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    access = Access.create!(account: old, organization: norte, kind: :coordinator)
    Invite.create!(organization: norte, email: "novo@exemplo.org", kind: :coordinator)

    allow(Access).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Access.new))

    expect {
      norte.replace_coordinator(access: access, email: "novo@exemplo.org")
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(Access.count).to eq(1)
    expect(Access.find(access.id)).to eq(access)
    expect(norte.reload.principal_coordinator_account).to eq(old)
    expect(Account.find_by(email: "novo@exemplo.org")).to be_nil
    expect(Invite.find_by(organization: norte, email: "novo@exemplo.org")).to be_present
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "remove deletes Accesses and Invites including the last coordinator" do
    norte = create_organization!(name: "ONG Norte")
    coordinator = Account.create!(email: "coordenador@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: coordinator, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)
    Invite.create!(organization: norte, email: "pessoa@exemplo.org", kind: :coordinator)

    expect(norte.remove).to be(true)

    expect(Organization.find_by(id: norte.id)).to be_nil
    expect(Access.where(organization_id: norte.id)).to be_empty
    expect(Invite.where(organization_id: norte.id)).to be_empty
    expect(Account.find(coordinator.id)).to eq(coordinator)
    expect(Account.find(submitter.id)).to eq(submitter)
  end

  it "remove refuses when a BankAccount exists" do
    norte = create_organization!(name: "ONG Norte")
    Access.create!(account: Account.create!(email: "coordenador@exemplo.org"), organization: norte, kind: :coordinator)
    BankAccount.create_for(organization: norte, name: "Conta Principal", compe: "001")

    expect(norte.remove).to be(false)
    expect(norte.errors[:base]).to eq([ "Esta organização já tem dados de fechamento e não pode ser removida." ])
    expect(Organization.find(norte.id)).to eq(norte)
    expect(norte.accesses.count).to eq(1)
    expect(BankAccount.where(organization: norte).count).to eq(1)
  end

  it "remove refuses when a Month exists" do
    norte = create_organization!(name: "ONG Norte")
    Access.create!(account: Account.create!(email: "coordenador@exemplo.org"), organization: norte, kind: :coordinator)
    Month.open(organization: norte, year_month: "2026-05")

    expect(norte.remove).to be(false)
    expect(Organization.find(norte.id)).to eq(norte)
    expect(norte.months.count).to eq(1)
  end

  it "remove refuses when a SupportingDocument exists" do
    norte = create_organization!(name: "ONG Norte")
    account = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: account, organization: norte, kind: :coordinator)
    SupportingDocument.create!(
      organization: norte,
      account: account,
      kind: "recibo",
      amount_cents: 100,
      document_on: Date.new(2026, 5, 11),
      payee: "Padaria"
    )

    expect(norte.remove).to be(false)
    expect(Organization.find(norte.id)).to eq(norte)
    expect(norte.supporting_documents.count).to eq(1)
  end

  it "remove refuses when a Justification exists" do
    norte = create_organization!(name: "ONG Norte")
    account = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: account, organization: norte, kind: :coordinator)
    Justification.create!(organization: norte, account: account, amount_cents: 100)

    expect(norte.remove).to be(false)
    expect(Organization.find(norte.id)).to eq(norte)
    expect(norte.justifications.count).to eq(1)
  end

  it "remove refuses when an ExtraExceptionKind exists" do
    norte = create_organization!(name: "ONG Norte")
    Access.create!(account: Account.create!(email: "coordenador@exemplo.org"), organization: norte, kind: :coordinator)
    ExtraExceptionKind.create_for(organization: norte, name: "Doação", justification: "Isento de documento de suporte.")

    expect(norte.remove).to be(false)
    expect(Organization.find(norte.id)).to eq(norte)
    expect(norte.extra_exception_kinds.count).to eq(1)
  end

  it "listed_coordinator_account is the principal coordinator" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    organization = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: zoe, organization: organization, kind: :coordinator)
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    Access.create!(account: Account.create!(email: "submitter@exemplo.org"), organization: organization, kind: :submitter)

    expect(organization.listed_coordinator_account).to eq(zoe)
    expect(organization.listed_coordinator_account.email).to eq("zoe@exemplo.org")
  end

  it "listed_coordinator_signed_in? follows the principal google_uid" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    organization = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: zoe, organization: organization, kind: :coordinator)
    Access.create!(account: ana, organization: organization, kind: :coordinator)

    expect(organization.listed_coordinator_signed_in?).to be(false)

    zoe.update!(google_uid: "uid-zoe")
    expect(organization.reload.listed_coordinator_signed_in?).to be(true)
  end

  it "home coordinator Accesses list the principal first then accounts.email" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    organization = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    bia = Account.create!(email: "bia@exemplo.org")
    Access.create!(account: zoe, organization: organization, kind: :coordinator)
    Access.create!(account: bia, organization: organization, kind: :coordinator)
    Access.create!(account: ana, organization: organization, kind: :coordinator)

    expect(organization.home_coordinator_accesses.map { |access| access.account.email }).to eq([
      "zoe@exemplo.org", "ana@exemplo.org", "bia@exemplo.org"
    ])
  end

  it "replace_coordinator promotes submitter Access then destroys the old principal" do
    old = Account.create!(email: "coordenador@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: old)
    access = Access.create!(account: old, organization: norte, kind: :coordinator)
    submitter = Account.create!(email: "submitter@exemplo.org")
    standing = Access.create!(account: submitter, organization: norte, kind: :submitter)

    result = nil
    expect {
      result = norte.replace_coordinator(access: access, email: " Submitter@Exemplo.ORG ")
    }.not_to change(Account, :count)

    expect(result.created_account).to be(false)
    expect(standing.reload.kind).to eq("coordinator")
    expect(norte.reload.principal_coordinator_account).to eq(submitter)
    expect(Access.find_by(id: access.id)).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "replace_coordinator reuses an existing Account and does not mail" do
    sul_account = Account.create!(email: "sul@exemplo.org")
    sul = create_organization!(name: "ONG Sul", principal_coordinator_account: sul_account)
    Access.create!(account: sul_account, organization: sul, kind: :coordinator)
    old = Account.create!(email: "coordenador@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: old)
    access = Access.create!(account: old, organization: norte, kind: :coordinator)

    expect {
      result = norte.replace_coordinator(access: access, email: "sul@exemplo.org")
      expect(result.created_account).to be(false)
    }.not_to change(Account, :count)

    expect(norte.reload.principal_coordinator_account).to eq(sul_account)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "register_coordinator sets principal_coordinator_account_id" do
    organization = Organization.register_coordinator(name: "ONG Norte", email: "coordenador@exemplo.org")
    account = Account.find_by!(email: "coordenador@exemplo.org")

    expect(organization.principal_coordinator_account).to eq(account)
  end
end
