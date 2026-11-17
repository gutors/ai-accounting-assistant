class ExtraExceptionKindsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    extra_exception_kind = ExtraExceptionKind.create_for(
      organization: focused_organization,
      name: params[:name],
      justification: params[:justification]
    )

    if extra_exception_kind.persisted?
      redirect_success("/setup", ActionToast.extra_exception_kind_created(extra_exception_kind))
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

    was_active = extra_exception_kind.active?
    extra_exception_kind.apply_active(params[:active]) if params.key?(:active)
    redirect_success("/setup", kind_toast(extra_exception_kind, was_active))
  end

  def destroy
    extra_exception_kind = focused_organization.extra_exception_kinds.find_by(id: params[:id])
    unless extra_exception_kind
      head :not_found
      return
    end

    name = extra_exception_kind.name
    if extra_exception_kind.destroy_if_unused
      redirect_success("/setup", ActionToast.extra_exception_kind_deleted(name))
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def kind_toast(extra_exception_kind, was_active)
    return ActionToast.extra_exception_kind_saved(extra_exception_kind) if extra_exception_kind.active? == was_active

    if extra_exception_kind.active?
      ActionToast.extra_exception_kind_activated(extra_exception_kind)
    else
      ActionToast.extra_exception_kind_deactivated(extra_exception_kind)
    end
  end
end
