class SubmitterInvitesController < ApplicationController
  before_action :require_coordinator_organization

  def create
    invite = Invite.create_pending(organization: focused_organization, email: params[:email], kind: :submitter)
    if invite.persisted?
      redirect_after_invite_mail(invite, sent_message: ActionToast.invite_sent(invite))
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  def mail
    invite = focused_organization.invites.submitter.find_by(id: params[:id])
    unless invite
      head :not_found
      return
    end

    redirect_after_invite_mail(invite, sent_message: ActionToast.invite_resent(invite))
  end

  def destroy
    invite = focused_organization.invites.submitter.find_by(id: params[:id])
    unless invite
      head :not_found
      return
    end

    email = invite.email
    invite.destroy!
    redirect_success(root_path, ActionToast.invite_cancelled(email))
  end
end
