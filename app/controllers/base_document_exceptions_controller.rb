class BaseDocumentExceptionsController < ApplicationController
  before_action :require_coordinator_organization

  def update
    unless focused_organization.apply_base_document_exception(params[:kind], params[:active])
      head :not_found
      return
    end

    redirect_success("/setup", ActionToast.base_document_exception_changed(params[:kind], base_offer_active?))
  end

  private

  def base_offer_active?
    column = Organization::BASE_DOCUMENT_EXCEPTION_COLUMNS[params[:kind].to_s]
    focused_organization.public_send(column)
  end
end
