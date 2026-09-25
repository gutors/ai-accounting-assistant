require "rails_helper"

RSpec.describe CoordinatorWelcomeMailer, type: :mailer do
  def deliver(organization)
    with_env("MAIL_FROM" => "venda@example.com") do
      described_class.welcome(organization).deliver_now
    end
    ActionMailer::Base.deliveries.last
  end

  it "welcome mail for the first organization" do
    account = Account.create!(email: "coordenador@exemplo.org")
    organization = Organization.create!(name: "ONG Norte")
    Access.create!(account: account, organization: organization, kind: :coordinator)

    message = deliver(organization)

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

    message = deliver(organization)

    expect(message.mime_type).to eq("text/plain")
    expect(message.body.decoded).to eq(
      "A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google."
    )
    expect(message.from).to eq([ "venda@example.com" ])
    expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
  end
end
