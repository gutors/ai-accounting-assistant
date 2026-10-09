class SupportingDocumentsController < ApplicationController
  before_action :require_focused_organization

  def index
    load_documents
  end

  def edit
    @document = mutate_document
  end

  def create
    document = SupportingDocument.insert(
      organization: focused_organization,
      account: current_account,
      kind: params[:kind],
      amount: params[:amount],
      date: params[:date],
      payee: params[:payee],
      observation: params[:observation],
      photo: params[:photo],
      xml: params[:xml],
      chave: params[:chave]
    )

    if document.errors.empty?
      redirect_success("/supporting_documents")
    else
      refuse_insert(document.errors[:base].first)
    end
  end

  def update
    @document = mutate_document
    return unless @document

    if submitter_month_locked?(@document)
      render_document_error(SupportingDocument::HAS_MONTH, template: :edit)
      return
    end

    attrs = {}
    %i[kind amount date payee observation chave].each do |key|
      attrs[key] = params[key] if params.key?(key)
    end
    attrs[:photo] = params[:photo] if params[:photo].present?
    attrs[:xml] = params[:xml] if params[:xml].present?
    @document.apply(**attrs)

    if @document.errors.empty?
      redirect_to "/supporting_documents", status: :found
    else
      render_document_error(@document.errors[:base].first, template: :edit)
    end
  end

  def sefaz_confirm
    document = mutate_document
    return unless document

    if submitter_month_locked?(document)
      render_document_error(SupportingDocument::HAS_MONTH)
      return
    end

    if document.confirm_identified_sefaz
      redirect_to "/supporting_documents", status: :found
    else
      render_document_error(document.errors[:base].first)
    end
  end

  def destroy
    document = mutate_document
    return unless document

    if document.withdraw
      redirect_to "/supporting_documents", status: :found
    else
      render_document_error(document.errors[:base].first)
    end
  end

  private

  def mutate_document
    document = focused_organization.supporting_documents.find_by(id: params[:id])
    unless document && (coordinator_on_focus? || document.account_id == current_account.id)
      head :not_found
      return
    end

    document
  end

  def submitter_month_locked?(document)
    !coordinator_on_focus? && document.month_id.present?
  end

  def render_document_error(message, template: :index)
    @document_error = message
    toast_now(kind: "error", message: message)
    if template == :edit
      render :edit, status: :unprocessable_content
    else
      load_documents
      render :index, status: :unprocessable_content
    end
  end

  def refuse_insert(message)
    @document_error = message
    toast_now(kind: "error", message: message)
    if turbo_stream_refusal?
      render_refusal_streams(message)
    else
      load_documents
      render :index, status: :unprocessable_content
    end
  end
end
