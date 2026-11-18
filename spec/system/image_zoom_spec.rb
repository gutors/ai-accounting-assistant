require "rails_helper"

RSpec.describe "Image zoom", type: :system do
  include_context "lote system"

  def amount_only_jpg
    Rails.root.join("spec/fixtures/files/ocr/amount_only.jpg")
  end

  def amount_only_png
    Rails.root.join("spec/fixtures/files/ocr/amount_only.png")
  end

  def amount_only_webp
    Rails.root.join("spec/fixtures/files/ocr/amount_only.webp")
  end

  def danfe_jpg
    Rails.root.join("spec/fixtures/files/ocr/danfe_fields.jpg")
  end

  def zoom_root
    find("[data-controller=image-zoom]")
  end

  def zoom_scale
    zoom_root["data-image-zoom-scale-value"].to_f
  end

  def wait_lote_image(name)
    expect(page).to have_css("[data-image-zoom-target=image][src^='blob:']", visible: true)
    expect(page).to have_css("[data-document-lote-target=caption]", text: name)
  end

  def attach_lote_raster(path)
    open_lote
    attach_file "file", path, make_visible: true
    wait_lote_image(File.basename(path))
  end

  def wheel_zoom(delta_y, ctrl: false)
    page.execute_script(<<~JS)
      const pane = document.querySelector("[data-image-zoom-target='pane']")
      pane.dispatchEvent(new WheelEvent("wheel", {
        deltaY: #{delta_y},
        ctrlKey: #{ctrl},
        bubbles: true,
        cancelable: true
      }))
    JS
  end

  def drag_image(dx, dy)
    page.execute_script(<<~JS)
      const img = document.querySelector("[data-image-zoom-target='image']")
      const startX = 120
      const startY = 80
      img.dispatchEvent(new PointerEvent("pointerdown", {
        clientX: startX, clientY: startY, bubbles: true, cancelable: true, pointerId: 1, button: 0
      }))
      window.dispatchEvent(new PointerEvent("pointermove", {
        clientX: startX + #{dx}, clientY: startY + #{dy}, bubbles: true, cancelable: true, pointerId: 1
      }))
      window.dispatchEvent(new PointerEvent("pointerup", {
        clientX: startX + #{dx}, clientY: startY + #{dy}, bubbles: true, cancelable: true, pointerId: 1
      }))
    JS
  end

  def pane_scroll
    page.evaluate_script(<<~JS)
      (function() {
        var pane = document.querySelector("[data-image-zoom-target='pane']")
        return { left: pane.scrollLeft, top: pane.scrollTop }
      })()
    JS
  end

  def ampliar
    find("button[aria-label='Ampliar']")
  end

  def reduzir
    find("button[aria-label='Reduzir']")
  end

  it "lote JPEG starts at scale 1 with Ampliar and Reduzir disabled" do
    attach_lote_raster(amount_only_jpg)

    expect(ampliar).to be_present
    expect(ampliar[:disabled]).to eq(false)
    expect(reduzir[:disabled]).to eq(true)
    expect(zoom_scale).to eq(1)
  end

  it "lote JPEG Ampliar from 1 sets scale 1.25" do
    attach_lote_raster(amount_only_jpg)

    ampliar.click

    expect(zoom_scale).to eq(1.25)
    expect(reduzir[:disabled]).to eq(false)
  end

  it "lote JPEG Ampliar at 4 stays 4 and disables Ampliar" do
    attach_lote_raster(amount_only_jpg)
    12.times { ampliar.click }
    expect(zoom_scale).to eq(4)
    expect(ampliar[:disabled]).to eq(true)

    page.execute_script("document.querySelector('[aria-label=\"Ampliar\"]').click()")

    expect(zoom_scale).to eq(4)
    expect(ampliar[:disabled]).to eq(true)
  end

  it "lote JPEG Reduzir from 1.25 sets scale 1" do
    attach_lote_raster(amount_only_jpg)
    ampliar.click
    expect(zoom_scale).to eq(1.25)

    reduzir.click

    expect(zoom_scale).to eq(1)
    expect(reduzir[:disabled]).to eq(true)
  end

  it "lote JPEG wheel and pinch zoom clamp between 1 and 4" do
    attach_lote_raster(amount_only_jpg)

    wheel_zoom(-120)
    expect(zoom_scale).to eq(1.25)

    reduzir.click
    expect(zoom_scale).to eq(1)
    wheel_zoom(-120, ctrl: true)
    expect(zoom_scale).to eq(1.25)

    reduzir.click
    expect(zoom_scale).to eq(1)
    wheel_zoom(120)
    expect(zoom_scale).to eq(1)

    12.times { ampliar.click }
    expect(zoom_scale).to eq(4)
    wheel_zoom(-120)
    expect(zoom_scale).to eq(4)
  end

  it "lote JPEG drag at scale 2 pans the proof pane" do
    attach_lote_raster(amount_only_jpg)
    4.times { ampliar.click }
    expect(zoom_scale).to eq(2)
    expect(pane_scroll["left"]).to eq(0)
    expect(pane_scroll["top"]).to eq(0)

    drag_image(-40, -40)

    expect(pane_scroll["left"].to_f.positive? || pane_scroll["top"].to_f.positive?).to eq(true)
  end

  it "lote PNG Ampliar from 1 sets scale 1.25" do
    attach_lote_raster(amount_only_png)

    ampliar.click

    expect(zoom_scale).to eq(1.25)
  end

  it "lote WebP Ampliar from 1 sets scale 1.25" do
    attach_lote_raster(amount_only_webp)

    ampliar.click

    expect(zoom_scale).to eq(1.25)
  end

  it "lote PDF has no Ampliar and embed toolbar=1" do
    open_lote
    attach_file "file", write_upload("danfe.pdf", "%PDF-1.1"), make_visible: true
    expect(page).to have_css("[data-document-lote-target=caption]", text: "danfe.pdf")

    expect(page).to have_no_css("button[aria-label='Ampliar']")
    expect(page).to have_no_css("button[aria-label='Reduzir']")
    embed = find("[data-document-lote-target=proof] embed[type='application/pdf']", visible: true)
    expect(embed[:src]).to include("#toolbar=1")
  end

  it "lote XML-only has no Ampliar" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml

    expect(page).to have_no_css("button[aria-label='Ampliar']")
    expect(page).to have_no_css("button[aria-label='Reduzir']")
  end

  it "lote second JPEG row resets scale to 1" do
    open_lote
    attach_file "file", [ amount_only_jpg, danfe_jpg ], make_visible: true
    wait_lote_image("amount_only.jpg")
    expect(page).to have_css("[data-lote-id]", text: "danfe_fields.jpg")
    ampliar.click
    expect(zoom_scale).to eq(1.25)

    find("[data-lote-id]", text: "danfe_fields.jpg").click

    expect(page).to have_css("[data-document-lote-target=caption]", text: "danfe_fields.jpg")
    expect(zoom_scale).to eq(1)
  end

  it "submitter JPEG Ampliar from 1 sets scale 1.25" do
    account, _organization = plant_submitter
    sign_in_through_google(account)
    visit "/supporting_documents"
    attach_file "file", amount_only_jpg, make_visible: true
    expect(page).to have_css("#identify-preview img[src^='blob:']", visible: true)

    expect(zoom_scale).to eq(1)
    ampliar.click

    expect(zoom_scale).to eq(1.25)
  end

  it "lote JPEG Ampliar visible at 390 without horizontal scroll" do
    open_lote
    page.current_window.resize_to(390, 844)
    attach_file "file", amount_only_jpg, make_visible: true
    wait_lote_image("amount_only.jpg")

    expect(ampliar).to be_visible
    expect(reduzir).to be_visible
    expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390
  end

  it "edit JPEG starts at scale 1 and Ampliar sets 1.25" do
    account, organization = plant_coordinator
    sign_in_through_google(account)
    photo = Rack::Test::UploadedFile.new(amount_only_jpg.to_s, "image/jpeg")
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "recibo",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      photo: photo
    )

    visit "/supporting_documents/#{document.id}/edit"

    expect(ampliar).to be_present
    expect(reduzir[:disabled]).to eq(true)
    expect(zoom_scale).to eq(1)
    ampliar.click
    expect(zoom_scale).to eq(1.25)
  end
end
