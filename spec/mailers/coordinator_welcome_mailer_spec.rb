require "rails_helper"

RSpec.describe CoordinatorWelcomeMailer, type: :mailer do
  def deliver(organization, account)
    with_env("MAIL_FROM" => "venda@example.com") do
      described_class.welcome(organization, account).deliver_now
    end
    ActionMailer::Base.deliveries.last
  end

  it "welcome mail for the first organization" do
    account = Account.create!(email: "coordenador@exemplo.org")
    organization = Organization.create!(name: "ONG Norte")
    Access.create!(account: account, organization: organization, kind: :coordinator)

    message = deliver(organization, account)

    expect(message.mime_type).to eq("text/plain")
    expect(message.body.decoded).to eq(
      "A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google."
    )
    expect(message.from).to eq([ "venda@example.com" ])
    expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "welcome mail when the account already coordinates another organization" do
    account = Account.create!(email: "coordenador@exemplo.org")
    other = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: other, kind: :coordinator)
    organization = Organization.create!(name: "ONG Norte")
    Access.create!(account: account, organization: organization, kind: :coordinator)

    message = deliver(organization, account)

    expect(message.mime_type).to eq("text/plain")
    expect(message.body.decoded).to eq(
      "A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google."
    )
    expect(message.from).to eq([ "venda@example.com" ])
    expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
  end

  it "welcome mail addresses the given Account" do
    ana = Account.create!(email: "ana@exemplo.org")
    novo = Account.create!(email: "novo@exemplo.org")
    organization = Organization.create!(name: "ONG Norte")
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    Access.create!(account: novo, organization: organization, kind: :coordinator)

    message = deliver(organization, novo)

    expect(message.to).to eq([ "novo@exemplo.org" ])
    expect(message.body.decoded).to include("novo@exemplo.org")
    expect(message.body.decoded).not_to include("ana@exemplo.org")
  end
end
