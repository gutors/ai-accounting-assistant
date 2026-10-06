require "rails_helper"

RSpec.describe "SEFAZ certificates", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def signed_in
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  it "POST /sefaz_certificate persists pfx and redirects" do
    _account, organization = signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
    expect(organization.sefaz_not_after).to eq(Date.new(2027, 9, 18))

    get "/setup"
    expect_certificate_listed_cnpj_row(response.body)
    expect(response.body).not_to include("passphrase-secreta")
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "POST /sefaz_certificate accepts p12" do
    signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_p12,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    get "/setup"
    expect(response.body).to include("11.222.333/0001-81")
  end

  it "GET /sefaz_certificate after install responds 404 without PKCS12 bytes" do
    signed_in
    der = sefaz_pkcs12_der(
      titular: "11222333000181",
      not_after: Date.new(2027, 9, 18),
      passphrase: "passphrase-secreta"
    )
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    get "/sefaz_certificate"

    expect(response).to have_http_status(:not_found)
    expect(response.body.b).not_to include(der.b)
  end

  it "POST pfx with passphrase errada returns 422 with install details open" do
    _account, organization = signed_in
    blob_count = ActiveStorage::Blob.count

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "errada"
    }

    expect(organization.reload.sefaz_titular_cnpj).to be_nil
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Não foi possível abrir o certificado com essa senha")
    expect(response.body).to include(certificate_empty_line)
    expect_certificate_install_fold(response.body, open: true)
    expect(page_doc(response.body).at_css("#certificate")["type"]).to eq("file")
    expect(page_doc(response.body).at_css("#certificate")["value"].to_s).to eq("")
    expect(page_doc(response.body).at_css("#passphrase")["value"].to_s).to eq("")
    expect(response.body).not_to include("errada")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Não foi possível abrir o certificado com essa senha")
    after = {
      blobs: ActiveStorage::Blob.count,
      sefaz: organization.reload.attributes.values_at(
        "sefaz_titular_cnpj", "sefaz_not_after", "sefaz_pkcs12_ciphertext", "sefaz_passphrase_ciphertext"
      )
    }
    expect(after[:blobs]).to eq(blob_count)
    expect(after[:sefaz]).to eq([ nil, nil, nil, nil ])
    joined = session.to_hash.values.map(&:to_s).join
    expect(joined).not_to include("errada")
    der = sefaz_pkcs12_der(titular: "11222333000181", not_after: Date.new(2027, 9, 18), passphrase: "passphrase-secreta")
    expect(session.to_hash.values.none? { |value| value.to_s.b.include?(der.b) }).to eq(true)
  end

  it "POST pfx with passphrase errada turbo stream 422 updates notice and toast only" do
    signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "errada"
    }, headers: turbo_stream_accept

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.media_type).to include("turbo-stream")
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("Não foi possível abrir o certificado com essa senha")
    expect(toast.text).to include("Não foi possível abrir o certificado com essa senha")
    expect(response.body).not_to include("errada")
    expect(Nokogiri::HTML::DocumentFragment.parse(response.body).at_css('form[action="/sefaz_certificate"]')).to be_nil
  end

  it "POST e-CPF against listed A1 returns 422 with install details open" do
    _account, organization = signed_in
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx(titular: "39053344705"),
      passphrase: "passphrase-secreta"
    }

    expect(organization.reload.sefaz_titular_cnpj).to eq("11222333000181")
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("O certificado deve ser e-CNPJ A1 vigente")
    expect(response.body).to include("11.222.333/0001-81")
    expect(certificate_remover(response.body)).to be_present
    expect_certificate_install_fold(response.body, open: true)
  end

  it "certificate error renders as a data-notice error alert" do
    signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx(titular: "39053344705"),
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("O certificado deve ser e-CNPJ A1 vigente")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("O certificado deve ser e-CNPJ A1 vigente")
  end

  it "POST e-CPF returns 422" do
    _account, organization = signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx(titular: "39053344705"),
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "POST expired A1 returns 422" do
    travel_to Date.new(2026, 5, 11) do
      _account, organization = signed_in

      post "/sefaz_certificate", params: {
        certificate: sefaz_pfx(not_after: Date.new(2026, 5, 10)),
        passphrase: "passphrase-secreta"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("O certificado deve ser e-CNPJ A1 vigente")
      expect(organization.reload.sefaz_titular_cnpj).to be_nil
    end
  end

  it "POST txt certificate returns 422" do
    _account, organization = signed_in

    post "/sefaz_certificate", params: {
      certificate: sefaz_txt_certificate,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "POST PKCS12 larger than 1048576 returns 422" do
    _account, organization = signed_in

    post "/sefaz_certificate", params: {
      certificate: oversized_sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "unauthenticated POST /sefaz_certificate responds 302 to /login" do
    expect do
      post "/sefaz_certificate", params: {
        certificate: sefaz_pfx,
        passphrase: "passphrase-secreta"
      }
    end.not_to change { Organization.where.not(sefaz_titular_cnpj: nil).count }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "submitter POST /sefaz_certificate persists none and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:not_found)
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "POST second A1 replaces titular on /setup" do
    signed_in
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx(titular: "12345678000101", name: "other.pfx"),
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:found)
    get "/setup"
    expect(response.body).to include("12.345.678/0001-01")
    expect(response.body).not_to include("11.222.333/0001-81")
  end

  it "DELETE /sefaz_certificate clears the slot and redirects" do
    _account, organization = signed_in
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    delete "/sefaz_certificate"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
    get "/setup"
    expect_certificate_absent_copy(response.body)
    expect_certificate_install_fold(response.body, open: false)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "unauthenticated DELETE /sefaz_certificate leaves certificate and responds 302 to /login" do
    account, organization = signed_in
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }
    delete "/session"

    delete "/sefaz_certificate"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(organization.reload.sefaz_titular_cnpj).to eq("11222333000181")
    expect(account).to be_present
  end

  it "submitter DELETE /sefaz_certificate leaves certificate and responds 404" do
    _coord, organization = plant_coordinator
    sign_in_as(_coord, organization: organization)
    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    delete "/sefaz_certificate"

    expect(response).to have_http_status(:not_found)
    expect(organization.reload.sefaz_titular_cnpj).to eq("11222333000181")
  end

  it "POST A1 with blank wrap key returns 422" do
    _account, organization = signed_in

    with_env("SEFAZ_WRAP_KEY" => nil) do
      post "/sefaz_certificate", params: {
        certificate: sefaz_pfx,
        passphrase: "passphrase-secreta"
      }
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("O certificado não pôde ser guardado")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "POST A1 while month closed still persists and redirects" do
    _account, organization = signed_in
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    post "/sefaz_certificate", params: {
      certificate: sefaz_pfx,
      passphrase: "passphrase-secreta"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.sefaz_titular_cnpj).to eq("11222333000181")
  end
end
