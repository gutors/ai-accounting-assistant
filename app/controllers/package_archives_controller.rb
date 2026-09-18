class PackageArchivesController < ApplicationController
  before_action :require_coordinator_organization

  def update
    if focused_organization.update_package_archive(params[:url])
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end
end
