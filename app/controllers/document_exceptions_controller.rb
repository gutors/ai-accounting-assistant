class DocumentExceptionsController < ApplicationController
  def create
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    month = find_opened_month
    return unless month

    payment = payment_on(month)
    return unless payment

    payment.mark_document_exception(params[:kind])
    if payment.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = payment.errors[:base].first
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end

  def destroy
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    month = find_opened_month
    return unless month

    payment = payment_on(month)
    return unless payment

    payment.unmark_document_exception
    if payment.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = payment.errors[:base].first
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end

  private

  def find_opened_month
    unless Month.valid_year_month?(params[:year_month])
      head :not_found
      return
    end

    month = focused_organization.months.find_by(year_month: params[:year_month])
    unless month
      head :not_found
      return
    end

    month
  end

  def payment_on(month)
    payment = Payment.joins(:bank_statement).find_by(id: params[:id], bank_statements: { month_id: month.id })
    unless payment
      head :not_found
      return
    end

    payment
  end
end
