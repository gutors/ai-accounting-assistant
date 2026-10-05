class PackageArchivesController < ApplicationController
  before_action :require_coordinator_organization

  def update
    if focused_organization.update_package_archive(params[:url])
      redirect_success("/setup")
    else
      load_setup
      @package_archive_editing = focused_organization.package_archive_url.present?
      render "setup/show", status: :unprocessable_content
    end
  end
end
