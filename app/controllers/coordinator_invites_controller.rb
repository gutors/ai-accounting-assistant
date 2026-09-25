class CoordinatorInvitesController < ApplicationController
  before_action :require_coordinator_organization

  def create
    invite = Invite.create_pending(organization: focused_organization, email: params[:email])
    if invite.persisted?
      session[:invite_mail_failed] = !deliver_invite(invite)
      redirect_to root_path, status: :found
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  def mail
    invite = focused_organization.invites.find_by(id: params[:id])
    unless invite
      head :not_found
      return
    end

    session[:invite_mail_failed] = !deliver_invite(invite)
    redirect_to root_path, status: :found
  end

  def destroy
    invite = focused_organization.invites.find_by(id: params[:id])
    unless invite
      head :not_found
      return
    end

    invite.destroy!
    redirect_to root_path, status: :found
  end
end
