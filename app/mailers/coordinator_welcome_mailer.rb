class CoordinatorWelcomeMailer < ApplicationMailer
  def welcome(organization)
    account = organization.accesses.coordinator.includes(:account).first.account
    sentence = if account.coordinator_accesses.count == 1
      "A organização #{organization.name} está pronta. Entre com o Google usando #{account.email}, pelo botão Entrar com Google."
    else
      "A organização #{organization.name} foi adicionada à sua conta. Entre com o Google usando #{account.email}, pelo botão Entrar com Google."
    end

    mail(
      to: account.email,
      subject: "Cadastro da organização #{organization.name}",
      content_type: "text/plain",
      body: sentence
    )
  end
end
