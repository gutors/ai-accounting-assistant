require "rails_helper"

RSpec.describe "Restore month folder", type: :request do
  def signed_closed_with_padaria_and_mercado
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ mercado ])
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    [ account, organization, month.reload, padaria.reload, mercado.reload ]
  end

  it "POST restore closed month rewrites the same folder_id and stays closed" do
    _account, _organization, month, padaria, mercado = signed_closed_with_padaria_and_mercado
    folder_id = month.month_folder_id
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(month.reload.closed?).to eq(true)
    expect(month.month_folder_id).to eq(folder_id)
    expect(padaria.reload.month_id).to eq(month.id)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to eq([])
    expect(writer.calls.size).to eq(2)
    call = writer.calls.last
    expect(call[:folder_id]).to eq(folder_id)
    expect(call[:files].keys).to include(
      "notas-sem-casamento/recibo-2026-05-11-padaria-central-#{padaria.id}.jpg",
      "notas/recibo-2026-05-11-mercado-silva-#{mercado.id}.jpg",
      "resumo-2026-05.xlsx"
    )
  end

  it "POST restore while open returns 422 Mes aberto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    calls = writer.calls.size

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês aberto")
    expect(writer.calls.size).to eq(calls)
    expect(month.reload.closed?).to eq(false)
  end

  it "POST restore when writer raises returns 422 and keeps folder_id" do
    _account, _organization, month, _padaria, _mercado = signed_closed_with_padaria_and_mercado
    folder_id = month.month_folder_id
    allow(PackageArchiveWriter.current).to receive(:replace_month_folder).and_raise(PackageArchiveWriter::Error)

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível gravar no arquivo do pacote")
    expect(month.reload.closed?).to eq(true)
    expect(month.month_folder_id).to eq(folder_id)
  end

  it "unauthenticated POST restore responds 302 to /login" do
    account, organization = plant_coordinator
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    month.close_for_send
    calls = writer.calls.size

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(writer.calls.size).to eq(calls)
  end

  it "submitter POST restore returns 404" do
    _account, organization, month, _padaria, _mercado = signed_closed_with_padaria_and_mercado
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    calls = writer.calls.size

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:not_found)
    expect(month.reload.closed?).to eq(true)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST restore of another organization month returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ready_to_close!(org_b)
    month_b, _statement = plant_month(org_b)
    month_b.close_for_send
    calls = writer.calls.size
    sign_in_as(account, organization: org_a)

    post "/months/2026-05/restore"

    expect(response).to have_http_status(:not_found)
    expect(month_b.reload.closed?).to eq(true)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST restore of never-opened 2026-04 returns 404" do
    _account, _organization, _month, _padaria, _mercado = signed_closed_with_padaria_and_mercado

    post "/months/2026-04/restore"

    expect(response).to have_http_status(:not_found)
  end

  describe "concurrent POST restore" do
    self.use_transactional_tests = false

    it "concurrent POST restore both return 302 and keep folder_id" do
      truncate_product_tables
      account, organization = plant_coordinator
      ready_to_close!(organization)
      month, _statement = plant_month(organization)
      month.close_for_send
      folder_id = month.reload.month_folder_id
      session_a = signed_in_session(account)
      session_b = signed_in_session(account)
      headers = { "User-Agent" => ChromeUserAgent::CHROME }
      statuses = []
      mutex = Mutex.new

      threads = [
        Thread.new do
          session_a.post("/months/2026-05/restore", headers: headers)
          mutex.synchronize { statuses << session_a.response.status }
        end,
        Thread.new do
          session_b.post("/months/2026-05/restore", headers: headers)
          mutex.synchronize { statuses << session_b.response.status }
        end
      ]
      threads.each(&:join)

      expect(month.reload.closed?).to eq(true)
      expect(month.month_folder_id).to eq(folder_id)
      expect(statuses).to eq([ 302, 302 ])
    ensure
      truncate_product_tables
    end
  end
end
