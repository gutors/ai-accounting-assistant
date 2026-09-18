module DocumentHelpers
  def photo_jpg(name = "recibo.jpg")
    upload_path(name, "jpeg-bytes", "image/jpeg")
  end

  def photo_named(name)
    upload_path(name, "jpeg-bytes-#{name}", "image/jpeg")
  end

  def xml_file(name = "nota.xml", content = "<nfe/>")
    upload_path(name, content, "application/xml")
  end

  def authorized_nfe_xml(vnf: "155.00", emit: "Padaria Central", dest: "ONG Destinataria", dhemi: "2026-05-11T10:00:00-03:00", chave: "43260511222333000181550010000000011123456781")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe">
        <NFe>
          <infNFe Id="NFe#{chave}">
            <ide><dhEmi>#{dhemi}</dhEmi></ide>
            <emit><xNome>#{emit}</xNome></emit>
            <dest><xNome>#{dest}</xNome></dest>
            <total><ICMSTot><vNF>#{vnf}</vNF></ICMSTot></total>
          </infNFe>
        </NFe>
      </nfeProc>
    XML
  end

  def authorized_xml(name = "autorizada.xml", **attrs)
    xml_file(name, authorized_nfe_xml(**attrs))
  end

  def xml_with_vnf
    xml_file("nota.xml", "<nfe><vNF>100.00</vNF></nfe>")
  end

  def photo_heic
    upload_path("foto.heic", "heic-bytes", "image/heic")
  end

  def xml_txt
    upload_path("nota.txt", "<vNF>100.00</vNF>", "text/plain")
  end

  def oversized_photo
    upload_path("foto.jpg", "x" * 10_485_761, "image/jpeg")
  end

  def oversized_xml
    upload_path("nota.xml", "x" * 10_485_761, "application/xml")
  end

  def photo_with_ext(ext)
    type = { "jpg" => "image/jpeg", "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp", "pdf" => "application/pdf" }.fetch(ext)
    upload_path("foto.#{ext}", "bytes-#{ext}", type)
  end
end
