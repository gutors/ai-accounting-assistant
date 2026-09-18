class SubmitterInvitesController < ApplicationController
  before_action :require_coordinator_organization

  def create
    invite = Invite.create_pending(organization: focused_organization, email: params[:email], kind: :submitter)
    if invite.persisted?
      redirect_to root_path, status: :found
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  def destroy
    invite = focused_organization.invites.submitter.find_by(id: params[:id])
    unless invite
      head :not_found
      return
    end

    invite.destroy!
    redirect_to root_path, status: :found
  end
end
