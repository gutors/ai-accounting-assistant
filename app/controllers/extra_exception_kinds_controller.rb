class ExtraExceptionKindsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    extra_exception_kind = ExtraExceptionKind.create_for(
      organization: focused_organization,
      name: params[:name],
      justification: params[:justification]
    )

    if extra_exception_kind.persisted?
      redirect_to "/setup", status: :found
    else
      load_setup
      @extra_exception_kind_form_open = true
      render "setup/show", status: :unprocessable_content
    end
  end

  def update
    extra_exception_kind = focused_organization.extra_exception_kinds.find_by(id: params[:id])
    unless extra_exception_kind
      head :not_found
      return
    end

    extra_exception_kind.apply_active(params[:active]) if params.key?(:active)
    redirect_to "/setup", status: :found
  end

  def destroy
    extra_exception_kind = focused_organization.extra_exception_kinds.find_by(id: params[:id])
    unless extra_exception_kind
      head :not_found
      return
    end

    if extra_exception_kind.destroy_if_unused
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end
end
