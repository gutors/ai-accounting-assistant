class AccessesController < ApplicationController
  before_action :require_coordinator_organization

  def destroy
    access = focused_organization.accesses.find_by(id: params[:id])
    unless access
      head :not_found
      return
    end

    if access.coordinator? && !may_revoke_coordinator?(access)
      head :not_found
      return
    end

    email = access.account.email
    if access.destroy
      redirect_success(root_path, ActionToast.access_revoked(email))
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  private

  def may_revoke_coordinator?(access)
    access.account_id != current_account.id &&
      focused_organization.principal_coordinator_account_id == current_account.id
  end
end
