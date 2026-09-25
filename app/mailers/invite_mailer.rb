class InviteMailer < ApplicationMailer
  def coordinator_invite(invite)
    mail(
      to: invite.email,
      subject: "Fechamento Mensal - Convite para #{invite.organization.name}",
      content_type: "text/plain",
      body: "Você foi convidado a fechar o mês da organização #{invite.organization.name}. Entre com o Google usando #{invite.email}, pelo botão Entrar com Google."
    )
  end

  def submitter_invite(invite)
    mail(
      to: invite.email,
      subject: "Fechamento Mensal - Convite para #{invite.organization.name}",
      content_type: "text/plain",
      body: "Você foi convidado a enviar documentos da organização #{invite.organization.name}. Entre com o Google usando #{invite.email}, pelo botão Entrar com Google."
    )
  end
end
