class SupportingDocumentsController < ApplicationController
  def index
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    load_documents
  end

  def create
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    document = SupportingDocument.insert(
      organization: focused_organization,
      account: current_account,
      kind: params[:kind],
      amount: params[:amount],
      date: params[:date],
      payee: params[:payee],
      observation: params[:observation],
      photo: params[:photo],
      xml: params[:xml]
    )

    if document.errors.empty?
      redirect_to "/supporting_documents", status: :found
    else
      @document_error = document.errors[:base].first
      load_documents
      render :index, status: :unprocessable_content
    end
  end

  def update
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    document = focused_organization.supporting_documents.find_by(id: params[:id])
    unless document
      head :not_found
      return
    end

    attrs = {}
    %i[kind amount date payee observation].each do |key|
      attrs[key] = params[key] if params.key?(key)
    end
    attrs[:photo] = params[:photo] if params[:photo].present?
    attrs[:xml] = params[:xml] if params[:xml].present?
    document.apply(**attrs)

    if document.errors.empty?
      redirect_to "/supporting_documents", status: :found
    else
      @document_error = document.errors[:base].first
      load_documents
      render :index, status: :unprocessable_content
    end
  end

  private

  def load_documents
    @documents = focused_organization.supporting_documents.listed
  end
end
