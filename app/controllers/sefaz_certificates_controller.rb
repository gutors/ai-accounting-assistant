class SefazCertificatesController < ApplicationController
  skip_before_action :require_account, only: :show
  before_action :require_coordinator_organization, except: :show

  def show
    head :not_found
  end

  def create
    if focused_organization.install_sefaz_certificate(file: params[:certificate], passphrase: params[:passphrase])
      redirect_success(setup_item_path("certificate"), ActionToast.certificate_installed(focused_organization))
    else
      @certificate_error = focused_organization.errors[:base].first
      toast_now(kind: "error", message: @certificate_error)
      if turbo_stream_refusal?
        render_refusal_streams(@certificate_error)
      else
        @setup_item = "certificate"
        load_setup
        render "setup/show", status: :unprocessable_content
      end
    end
  end

  def destroy
    titular = focused_organization.sefaz_titular_display
    focused_organization.remove_sefaz_certificate
    redirect_success(setup_item_path("certificate"), ActionToast.certificate_removed(titular))
  end
end
