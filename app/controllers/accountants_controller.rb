class AccountantsController < ApplicationController
  before_action :require_coordinator_organization

  def update
    if focused_organization.update_accountant(accountant_params)
      redirect_success("/setup")
    else
      load_setup
      @accountant_editing = true
      @accountant_error = focused_organization.errors[:base].first
      toast_now(kind: "error", message: @accountant_error)
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def accountant_params
    params.permit(:presentation_name, :tax_id, :legal_name, :pix_key, :destination_email)
  end
end
