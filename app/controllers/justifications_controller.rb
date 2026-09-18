class JustificationsController < ApplicationController
  before_action :require_focused_organization
  before_action :require_submitter_on_focus

  def create
    justification = Justification.declare(
      organization: focused_organization,
      account: current_account,
      amount: params[:amount],
      supporting_document_ids: params[:supporting_document_ids]
    )
    if justification.persisted?
      redirect_to "/supporting_documents", status: :found
    else
      @document_error = justification.errors[:base].first
      load_documents
      render "supporting_documents/index", status: :unprocessable_content
    end
  end

  def update
    justification = focused_organization.justifications.find_by(id: params[:id], account_id: current_account.id)
    unless justification
      head :not_found
      return
    end

    if justification.replace_amount(params[:amount])
      redirect_to "/supporting_documents", status: :found
    else
      @document_error = justification.errors[:base].first
      load_documents
      render "supporting_documents/index", status: :unprocessable_content
    end
  end

  private

  def require_submitter_on_focus
    head :not_found if coordinator_on_focus?
  end
end
