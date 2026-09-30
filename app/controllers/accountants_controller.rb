class AccountantsController < ApplicationController
  before_action :require_coordinator_organization

  def update
    if focused_organization.update_accountant(accountant_params)
      redirect_to "/setup", status: :found
    else
      load_setup
      @accountant_error = focused_organization.errors[:base].first
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def accountant_params
    params.permit(:presentation_name, :tax_id, :legal_name, :pix_key, :destination_email)
  end
end
