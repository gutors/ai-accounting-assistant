require "rails_helper"

RSpec.describe InviteMailer, type: :mailer do
  def deliver(kind, invite)
    with_env("MAIL_FROM" => "venda@example.com") do
      described_class.public_send(kind, invite).deliver_now
    end
    ActionMailer::Base.deliveries.last
  end

  it "coordinator invite mail" do
    organization = create_organization!(name: "ONG Norte")
    invite = Invite.create!(organization: organization, email: "pessoa@exemplo.org", kind: :coordinator)

    message = deliver(:coordinator_invite, invite)

    expect(message.mime_type).to eq("text/plain")
    expect(message.from).to eq([ "venda@example.com" ])
    expect(message.to).to eq([ "pessoa@exemplo.org" ])
    expect(message.subject).to eq("Fechamento Mensal - Convite para ONG Norte")
    expect(message.body.decoded).to eq(
      "Você foi convidado a fechar o mês da organização ONG Norte. Entre com o Google usando pessoa@exemplo.org, pelo botão Entrar com Google."
    )
  end

  it "submitter invite mail" do
    organization = create_organization!(name: "ONG Norte")
    invite = Invite.create!(organization: organization, email: "docs@exemplo.org", kind: :submitter)

    message = deliver(:submitter_invite, invite)

    expect(message.mime_type).to eq("text/plain")
    expect(message.subject).to eq("Fechamento Mensal - Convite para ONG Norte")
    expect(message.body.decoded).to eq(
      "Você foi convidado a enviar documentos da organização ONG Norte. Entre com o Google usando docs@exemplo.org, pelo botão Entrar com Google."
    )
  end
end
