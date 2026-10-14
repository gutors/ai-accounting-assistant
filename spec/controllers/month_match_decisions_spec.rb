require "rails_helper"

class MonthMatchDecisionProbe < ApplicationController
  public :after_month_mutate_path, :assign_matches_account_filter, :matches_screen?, :render_after_month_mutate

  attr_accessor :head_status, :render_call, :page_loaded
  attr_writer :focused_organization

  def focused_organization
    @focused_organization
  end

  def head(status, *)
    self.head_status = status
  end

  def load_matches_page
    self.page_loaded = :matches
  end

  def load_month_page
    self.page_loaded = :month
  end

  def render(template = nil, status: nil, **)
    self.render_call = { template: template, status: status }
  end
end

class MonthMatchStripProbe < DocumentExceptionsController
  public :selected_missing_payment

  attr_accessor :selection_error, :head_status
  attr_writer :focused_organization

  def focused_organization
    @focused_organization
  end

  def assign_matches_account_filter
    true
  end

  def head(status, *)
    self.head_status = status
  end

  def render_after_month_mutate(month, message)
    self.selection_error = [ month, message ]
    nil
  end
end

RSpec.describe "Month match controller decisions" do
  def decision_probe(params)
    controller = MonthMatchDecisionProbe.new
    request = ActionDispatch::TestRequest.create
    controller.set_request!(request)
    controller.params = ActionController::Parameters.new(params)
    controller
  end

  def strip_probe(params)
    controller = MonthMatchStripProbe.new
    request = ActionDispatch::TestRequest.create
    controller.set_request!(request)
    controller.params = ActionController::Parameters.new(params)
    controller
  end

  def month_double
    instance_double(Month, year_month: "2026-05")
  end

  it "after_month_mutate_path is month unless screen is matches" do
    month = month_double
    expect(decision_probe({}).after_month_mutate_path(month)).to eq("/months/2026-05")
    expect(decision_probe(screen: "matches").after_month_mutate_path(month)).to eq("/months/2026-05/matches")
    expect(decision_probe(screen: "matches", bank_account_id: "9").after_month_mutate_path(month)).to eq(
      "/months/2026-05/matches?bank_account_id=9"
    )
  end

  it "assign_matches_account_filter omit valid zero foreign and inactive" do
    _account, organization = plant_coordinator
    alfa = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    foreign = BankAccount.create_for(organization: create_organization!(name: "ONG Sul"), name: "Conta Estranha", compe: "033")
    inactive = BankAccount.create_for(organization: organization, name: "Conta Morta", compe: "237")
    inactive.update!(active: false)

    omitted = decision_probe({})
    omitted.focused_organization = organization
    expect(omitted.assign_matches_account_filter).to eq(true)
    expect(omitted.instance_variable_get(:@bank_account_id)).to be_nil

    valid = decision_probe(bank_account_id: alfa.id)
    valid.focused_organization = organization
    expect(valid.assign_matches_account_filter).to eq(true)
    expect(valid.instance_variable_get(:@bank_account_id)).to eq(alfa.id)

    [ 0, foreign.id, inactive.id ].each do |bad_id|
      probe = decision_probe(bank_account_id: bad_id)
      probe.focused_organization = organization
      expect(probe.assign_matches_account_filter).to eq(false)
      expect(probe.head_status).to eq(:not_found)
    end
  end

  it "render_after_month_mutate renders matches show when screen is matches" do
    month = month_double
    matches = decision_probe(screen: "matches")
    matches.focused_organization = create_organization!(name: "ONG Norte")
    matches.render_after_month_mutate(month, Match::BAD_SHAPE)
    expect(matches.page_loaded).to eq(:matches)
    expect(matches.render_call).to eq(template: "matches/show", status: :unprocessable_content)

    month_page = decision_probe({})
    month_page.render_after_month_mutate(month, Match::BAD_SHAPE)
    expect(month_page.page_loaded).to eq(:month)
    expect(month_page.render_call).to eq(template: "months/show", status: :unprocessable_content)
  end

  it "selected_missing_payment requires exactly one payment id" do
    _account, organization = plant_coordinator
    month, statement = plant_month(organization)
    one = plant_payment(statement, 22000, history: "Um")
    two = plant_payment(statement, 18000, history: "Dois")

    zero = strip_probe(kind: "bank_fee")
    expect(zero.selected_missing_payment(month)).to be_nil
    expect(zero.selection_error).to eq([ month, DocumentExceptionsController::SELECTION ])

    many = strip_probe(payment_ids: [ one.id, two.id ], kind: "bank_fee")
    expect(many.selected_missing_payment(month)).to be_nil
    expect(many.selection_error).to eq([ month, DocumentExceptionsController::SELECTION ])

    single = strip_probe(payment_ids: [ one.id ], kind: "bank_fee")
    expect(single.selected_missing_payment(month)).to eq(one)

    missing = strip_probe(payment_ids: [ one.id + 1_000_000 ], kind: "bank_fee")
    expect(missing.selected_missing_payment(month)).to be_nil
    expect(missing.head_status).to eq(:not_found)
  end
end
