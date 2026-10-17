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

  def authorized_nfcom_xml(vnf: "256.80", emit: "EMPRESA TELECOM EXEMPLO S.A.", dhemi: "2026-06-15T21:53:53-03:00", chave: "27260611222333000181620010008920781028142810")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <nfcomProc xmlns="http://www.portalfiscal.inf.br/nfcom">
        <NFCom>
          <infNFCom Id="NFCom#{chave}">
            <ide><dhEmi>#{dhemi}</dhEmi></ide>
            <emit><xNome>#{emit}</xNome></emit>
            <total><vNF>#{vnf}</vNF></total>
          </infNFCom>
        </NFCom>
      </nfcomProc>
    XML
  end

  def authorized_nf3e_xml(vnf: "189.40", emit: "Companhia Energetica Exemplo", dhemi: "2026-05-20T00:00:00-03:00", chave: "27260611222333000181660010000008920781028142")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <nf3eProc xmlns="http://www.portalfiscal.inf.br/nf3e">
        <NF3e>
          <infNF3e Id="NF3e#{chave}">
            <ide><dhEmi>#{dhemi}</dhEmi></ide>
            <emit><xNome>#{emit}</xNome></emit>
            <total><vNF>#{vnf}</vNF></total>
          </infNF3e>
        </NF3e>
      </nf3eProc>
    XML
  end

  def authorized_nfse_xml(vserv: "610.00", emit: "Contabilidade Exemplo Ltda", dhemi: "2026-05-06T10:00:00-03:00", chave: "41260511222333000181000000000000000000000000000001")
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <NFSe xmlns="http://www.sped.fazenda.gov.br/nfse">
        <infNFSe Id="NFS#{chave}">
          <ide><dhEmi>#{dhemi}</dhEmi></ide>
          <emit><xNome>#{emit}</xNome></emit>
          <valores><vServ>#{vserv}</vServ></valores>
        </infNFSe>
      </NFSe>
    XML
  end

  def cte_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <cteProc xmlns="http://www.portalfiscal.inf.br/cte">
        <CTe>
          <infCte Id="CTe43260511222333000181570010000000011123456781">
            <ide><dhEmi>2026-05-11T10:00:00-03:00</dhEmi></ide>
          </infCte>
        </CTe>
      </cteProc>
    XML
  end

  def municipal_nfse_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <CompNfse xmlns="http://www.abrasf.org.br/nfse.xsd">
        <Nfse>
          <InfNfse Id="1">
            <Valores><ValorServicos>610.00</ValorServicos></Valores>
          </InfNfse>
        </Nfse>
      </CompNfse>
    XML
  end

  def nfcom_file(name = "nfcom.xml")
    xml_file(name, authorized_nfcom_xml)
  end

  def nf3e_file(name = "nf3e.xml")
    xml_file(name, authorized_nf3e_xml)
  end

  def nfse_file(name = "nfse.xml")
    xml_file(name, authorized_nfse_xml)
  end

  def cte_file(name = "cte.xml")
    xml_file(name, cte_xml)
  end

  def municipal_nfse_file(name = "municipal-nfse.xml")
    xml_file(name, municipal_nfse_xml)
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
