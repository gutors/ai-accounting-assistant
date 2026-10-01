class FocusController < ApplicationController
  def create
    organization = current_account.organizations.find_by(id: params[:organization_id])
    unless organization
      head :not_found
      return
    end

    session[:organization_id] = organization.id
    redirect_success(root_path)
  end
end
