class BaseDocumentExceptionsController < ApplicationController
  before_action :require_coordinator_organization

  def update
    unless focused_organization.apply_base_document_exception(params[:kind], params[:active])
      head :not_found
      return
    end

    redirect_success("/setup")
  end
end
