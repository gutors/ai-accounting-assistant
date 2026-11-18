require "rails_helper"

RSpec.describe "Document lote progress", type: :system do
  include_context "lote system"

  def ticks
    page.all("[data-document-lote-target=rule] > span", visible: :all)
  end

  def tick_style(index)
    page.evaluate_script(<<~JS)
      (function() {
        var tick = document.querySelectorAll("[data-document-lote-target=rule] > span")[#{index}]
        if (!tick) return null
        var s = getComputedStyle(tick)
        return { background: s.backgroundColor, shadow: s.boxShadow, width: tick.getBoundingClientRect().width }
      })()
    JS
  end

  def wave_copy
    page.find("[data-document-lote-target=wave]", visible: :all).text
  end

  def rule_shown?
    page.has_css?("[data-document-lote-target=rule]:not([hidden])", visible: :all)
  end

  def status_of(name)
    page.find("[data-lote-id]", text: name).find("[data-lote-status]").text
  end

  def row_of(name)
    page.find("[data-lote-id]", text: name)
  end

  def ten_xmls
    wave_xmls(*%w[a.xml b.xml c.xml d.xml e.xml f.xml g.xml h.xml i.xml j.xml])
  end

  it "ten files paint ten ticks in the three states" do
    open_lote
    gate_identify_waves
    attach_file "file", ten_xmls, make_visible: true
    wait_identify_started(1)

    expect(ticks.size).to eq(10)
    (0..3).each { |index| expect(tick_style(index)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset") }
    (4..9).each { |index| expect(tick_style(index)["background"]).to eq("rgb(199, 213, 202)") }

    release_identify_wave
    wait_identify_started(2)

    expect(wave_copy).to eq("Identificando os documentos 5 a 8 de 10")
    expect(ticks.size).to eq(10)
    (0..3).each { |index| expect(tick_style(index)["background"]).to eq("rgb(46, 107, 78)") }
    (4..7).each do |index|
      expect(tick_style(index)["background"]).to eq("rgb(243, 245, 241)")
      expect(tick_style(index)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset")
    end
    (8..9).each { |index| expect(tick_style(index)["background"]).to eq("rgb(199, 213, 202)") }
  end

  it "sentence names every wave bounds and the total" do
    open_lote
    gate_identify_waves
    attach_file "file", ten_xmls, make_visible: true
    wait_identify_started(1)
    expect(wave_copy).to eq("Identificando os documentos 1 a 4 de 10")

    release_identify_wave
    wait_identify_started(2)
    expect(wave_copy).to eq("Identificando os documentos 5 a 8 de 10")

    release_identify_wave
    wait_identify_started(3)
    expect(wave_copy).to eq("Identificando os documentos 9 a 10 de 10")

    visit "/supporting_documents"
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)
    expect(wave_copy).to eq("Identificando os documentos 1 a 4 de 5")

    release_identify_wave
    wait_identify_started(2)
    expect(wave_copy).to eq("Identificando o documento 5 de 5")
  end

  it "four files show one wave over four ticks" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml"), make_visible: true
    wait_identify_started(1)

    expect(wave_copy).to eq("Identificando os documentos 1 a 4 de 4")
    expect(ticks.size).to eq(4)
  end

  it "one file keeps the proof square sentence and no rule" do
    open_lote
    slow_fetch("/supporting_documents/identify_batch", 800)
    attach_file "file", write_upload("danfe-mercado.jpg", "jpeg-bytes"), make_visible: true

    expect(page).to have_css("[data-document-lote-target=identifying]", text: "Identificando o arquivo…", visible: true)
    expect(rule_shown?).to eq(false)
    expect(wave_copy).to eq("")
  end

  it "five XMLs split Identificando from Na fila" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)

    %w[a.xml b.xml c.xml d.xml].each { |name| expect(status_of(name)).to eq("Identificando") }
    expect(status_of("e.xml")).to eq("Na fila")
    %w[a.xml b.xml c.xml d.xml e.xml].each { |name| expect(row_of(name)).to have_no_content("Identificando o arquivo…") }
    expect(page).to have_no_css("[data-lote-status]", text: "Identificando o arquivo…")

    release_identify_wave
    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 4)
    expect(status_of("e.xml")).to eq("Identificando")
    %w[a.xml b.xml c.xml d.xml e.xml].each { |name| expect(row_of(name)).to have_no_content("Identificando o arquivo…") }

    release_identify_wave
    expect(status_of("e.xml")).to eq("Pronto")
    expect(page).to have_no_css("[data-lote-status]", text: "Identificando o arquivo…")
    %w[a.xml b.xml c.xml d.xml e.xml].each { |name| expect(row_of(name)).to have_no_content("Identificando o arquivo…") }

    visit "/supporting_documents"
    gate_identify_waves
    attach_file "file", [ write_upload("nota.xml", "<nfe/>") ] + wave_xmls("a.xml", "b.xml", "c.xml", "d.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave

    erro = page.find("[data-lote-id]", text: "nota.xml")
    expect(erro).to have_css("[data-lote-status]", text: "Erro")
    expect(erro).to have_content("O XML da nota fiscal não pôde ser lido")
    expect(erro).to have_no_content("Identificando o arquivo…")
  end

  it "unreadable XML fills one margem tick" do
    open_lote
    gate_identify_waves
    attach_file "file", [ write_upload("nota.xml", "<nfe/>") ] + wave_xmls("a.xml", "b.xml", "c.xml", "d.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave
    wait_identify_started(2)

    expect(tick_style(0)["background"]).to eq("rgb(180, 55, 42)")
    (1..3).each { |index| expect(tick_style(index)["background"]).to eq("rgb(46, 107, 78)") }
    expect(tick_style(4)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset")
    err = page.find("[data-lote-id]", text: "nota.xml")
    expect(err).to have_css("[data-lote-status]", text: "Erro")
    expect(err).to have_content("O XML da nota fiscal não pôde ser lido")
  end

  it "last wave leaves no rule and the count on Incluir prontos" do
    open_lote
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true

    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 5)
    expect(rule_shown?).to eq(false)
    expect(wave_copy).to eq("")
    expect(page).to have_button("Incluir prontos (5)")
  end

  it "Retirar repaints the rule with one tick fewer" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)

    page.find("[data-lote-id]", text: "a.xml").click
    click_button "Retirar"

    expect(ticks.size).to eq(4)
    expect(wave_copy).to eq("Identificando os documentos 1 a 3 de 4")
    (0..2).each { |index| expect(tick_style(index)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset") }
    expect(tick_style(3)["background"]).to eq("rgb(199, 213, 202)")
  end

  it "second picker paints seven ticks and queues the new files" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)

    attach_file "file", wave_xmls("f.xml", "g.xml"), make_visible: true

    expect(ticks.size).to eq(7)
    (0..3).each { |index| expect(tick_style(index)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset") }
    expect(status_of("f.xml")).to eq("Na fila")
    expect(status_of("g.xml")).to eq("Na fila")
    expect(wave_copy).to eq("Identificando os documentos 1 a 4 de 7")
  end

  it "thirty files keep every tick eight pixels at 390" do
    open_lote
    gate_identify_waves
    page.current_window.resize_to(390, 844)
    names = (1..30).map { |index| format("doc%02d.xml", index) }
    attach_file "file", wave_xmls(*names), make_visible: true
    wait_identify_started(1)

    expect(ticks.size).to eq(30)
    widths = (0..29).map { |index| tick_style(index)["width"] }
    expect(widths.min).to be >= 8

    section = page.evaluate_script("document.querySelector('section[data-controller=document-lote]').clientWidth")
    rule = page.evaluate_script("document.querySelector('[data-document-lote-target=rule]').getBoundingClientRect().width")
    without_rule = page.evaluate_script(<<~JS)
      (function() {
        var rule = document.querySelector("[data-document-lote-target=rule]")
        rule.hidden = true
        var width = document.documentElement.scrollWidth
        rule.hidden = false
        return width
      })()
    JS
    expect(rule).to be <= section
    expect(page.evaluate_script("document.documentElement.scrollWidth")).to eq(without_rule)
  end

  it "each Situacao matches its tick" do
    open_lote
    gate_identify_waves
    attach_file "file", [
      write_upload("nota.xml", "<nfe/>"),
      write_upload("empty.jpg", "jpeg-bytes")
    ] + wave_xmls("b.xml", "c.xml", "d.xml", "e.xml", "f.xml", "g.xml", "h.xml", "i.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave
    wait_identify_started(2)

    expect(status_of("nota.xml")).to eq("Erro")
    expect(tick_style(0)["background"]).to eq("rgb(180, 55, 42)")
    expect(status_of("empty.jpg")).to eq("Digitar")
    expect(tick_style(1)["background"]).to eq("rgb(46, 107, 78)")
    expect(status_of("b.xml")).to eq("Pronto")
    expect(status_of("c.xml")).to eq("Pronto")
    expect(tick_style(3)["background"]).to eq("rgb(46, 107, 78)")
    expect(status_of("d.xml")).to eq("Identificando")
    expect(tick_style(4)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset")
    expect(status_of("h.xml")).to eq("Na fila")
    expect(tick_style(8)["background"]).to eq("rgb(199, 213, 202)")
    expect(tick_style(9)["background"]).to eq("rgb(199, 213, 202)")
  end

  it "selecting a queued row leaves the book empty" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)

    page.find("[data-lote-id]", text: "e.xml").click

    expect(page).to have_css('[data-lote-id][aria-selected="true"]', text: "e.xml")
    expect(find_field("amount").value).to eq("")
    expect(find_field("date").value).to eq("")
    expect(find_field("payee").value).to eq("")
    expect(page).to have_no_css("[data-document-lote-target=identifying]", visible: true)
  end

  it "Incluir prontos while a wave is in flight repaints the rule" do
    open_lote
    gate_identify_waves
    attach_file "file", ten_xmls, make_visible: true
    wait_identify_started(1)
    release_identify_wave
    wait_identify_started(2)

    click_button "Incluir prontos (4)"

    expect(page).to have_css("[data-lote-id]", count: 6)
    expect(ticks.size).to eq(6)
    (0..3).each { |index| expect(tick_style(index)["shadow"]).to include("rgb(46, 107, 78) 0px 0px 0px 2px inset") }
    (4..5).each { |index| expect(tick_style(index)["background"]).to eq("rgb(199, 213, 202)") }
    expect(wave_copy).to eq("Identificando os documentos 1 a 4 de 6")
  end
end
