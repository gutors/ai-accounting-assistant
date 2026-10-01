class SefazCertificatesController < ApplicationController
  skip_before_action :require_account, only: :show
  before_action :require_coordinator_organization, except: :show

  def show
    head :not_found
  end

  def create
    if focused_organization.install_sefaz_certificate(file: params[:certificate], passphrase: params[:passphrase])
      redirect_success("/setup")
    else
      load_setup
      @certificate_error = focused_organization.errors[:base].first
      toast_now(kind: "error", message: @certificate_error)
      render "setup/show", status: :unprocessable_content
    end
  end

  def destroy
    focused_organization.remove_sefaz_certificate
    redirect_success("/setup")
  end
end
