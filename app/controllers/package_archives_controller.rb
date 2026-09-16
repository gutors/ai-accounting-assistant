class PackageArchivesController < ApplicationController
  def update
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    if focused_organization.update_package_archive(params[:url])
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end
end
