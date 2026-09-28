module AdministrationHelpers
  def as_seller
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
      google_callback(email: "seller@example.com", uid: "uid-seller")
      yield
    end
  end

  def administration_routes
    [
      [ :get, "/administration" ],
      [ :get, "/administration/new" ],
      [ :get, "/administration/1/edit" ],
      [ :post, "/administration" ],
      [ :post, "/administration/confirm" ],
      [ :post, "/administration/correct" ],
      [ :post, "/administration/mail" ],
      [ :post, "/administration/another" ],
      [ :post, "/administration/name" ],
      [ :post, "/administration/name/continue" ],
      [ :post, "/administration/name/cancel" ],
      [ :post, "/administration/name/confirm" ],
      [ :post, "/administration/email" ],
      [ :post, "/administration/email/continue" ],
      [ :post, "/administration/email/cancel" ],
      [ :post, "/administration/email/confirm" ],
      [ :delete, "/administration" ]
    ]
  end

  def follow_administration(path = "/administration")
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(path)
    follow_redirect!
  end

  def organization_row(organization)
    page.at_css("[data-organization-id='#{organization.id}']")
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def administration_column
    column = page.css("main div").find { |node| node["class"].to_s.split.include?("max-w-[28rem]") }
    expect(column).not_to be_nil
    expect(column["class"]).not_to include("mx-auto")
    column
  end

  def expect_empty_list
    expect(response).to have_http_status(:ok)
    expect(page.at_css("h1").text.strip).to eq("Administração")
    add = page.css("a").find { |link| link.text.strip == "Adicionar organização" }
    expect(add["href"]).to eq("/administration/new")
    expect(add["class"]).to include("bg-caixa")
    expect(add["class"]).to include("font-semibold")
    expect(page.at_css('input[name="name"]')).to be_nil
    expect(page.at_css('input[name="email"]')).to be_nil
    expect(page.css("[data-organization-id]")).to be_empty
    expect(response.body).to include("Nenhuma organização cadastrada.")
    expect(response.body).not_to include("Cadastre a organização e o coordenador que vai fechá-la.")
    expect(response.body).not_to include("Cadastrar outra organização")
    expect(page.css("main svg")).to be_empty
  end

  def expect_add_form
    expect(response).to have_http_status(:ok)
    expect(page.at_css("h1").text.strip).to eq("Adicionar organização")
    expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
    expect(page.css("[data-notice='error']")).to be_empty
    column = page.at_css("main div")
    expect(column["class"]).to include("max-w-[28rem]")
    expect(column["class"]).not_to include("mx-auto")
    labels = page.css("label")
    expect(labels.map { |label| label.text.strip }).to eq([ "Nome da organização", "E-mail do coordenador" ])
    labels.each do |label|
      field = label.next_element
      expect(field.name).to eq("input")
      expect(field["value"].to_s).to eq("")
      %w[w-full border border-rule bg-sheet].each { |css| expect(field["class"]).to include(css) }
    end
    submit = page.at_css('input[type="submit"]')
    expect(submit["value"]).to eq("Continuar")
    expect(submit["class"]).to include("bg-caixa")
    expect(page.css("main svg")).to be_empty
    expect(response.body).not_to include("Cadastrar outra organização")
  end

  def raise_delivery
    delivery = instance_double(ActionMailer::MessageDelivery)
    allow(CoordinatorWelcomeMailer).to receive(:welcome).and_return(delivery)
    allow(delivery).to receive(:deliver_now).and_raise(RuntimeError, "smtp down")
  end
end
