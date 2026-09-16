class AccessesController < ApplicationController
  def destroy
    access = focused_organization&.accesses&.find_by(id: params[:id])
    unless access
      head :not_found
      return
    end

    if access.destroy
      redirect_to root_path, status: :found
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end
end
