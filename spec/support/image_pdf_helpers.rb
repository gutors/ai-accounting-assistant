require "zlib"
require "chunky_png"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"

module ImagePdfHelpers
  def ocr_png(name)
    Rails.root.join("spec/fixtures/files/ocr", name).binread
  end

  def code128_png(chave = "43260511222333000181550010000000011123456781")
    Barby::Code128B.new(chave).to_png(xdim: 2, height: 80, margin: 16)
  end

  def pdf_upload(name, bytes)
    upload_path(name, bytes, "application/pdf")
  end

  def pngs_to_pdf(*png_bytes)
    images = png_bytes.map { |bytes| ChunkyPNG::Image.from_blob(bytes) }
    objects = []

    page_nums = []
    images.each_with_index do |image, index|
      page_num = 3 + (index * 3)
      contents_num = page_num + 1
      image_num = page_num + 2
      page_nums << page_num
      width = image.width
      height = image.height
      rgb = +"".b
      height.times do |y|
        width.times do |x|
          color = image[x, y]
          rgb << ChunkyPNG::Color.r(color).chr
          rgb << ChunkyPNG::Color.g(color).chr
          rgb << ChunkyPNG::Color.b(color).chr
        end
      end
      compressed = Zlib::Deflate.deflate(rgb, Zlib::BEST_SPEED)
      contents = "q #{width} 0 0 #{height} 0 0 cm /Im#{index} Do Q\n"
      objects[page_num] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{width} #{height}] " \
                          "/Contents #{contents_num} 0 R /Resources << /XObject << /Im#{index} #{image_num} 0 R >> >> >>\n"
      objects[contents_num] = pdf_stream(contents.b)
      objects[image_num] = "<< /Type /XObject /Subtype /Image /Width #{width} /Height #{height} " \
                           "/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode " \
                           "/Length #{compressed.bytesize} >>\nstream\n".b + compressed + "endstream\n".b
    end

    kids = page_nums.map { |num| "#{num} 0 R" }.join(" ")
    objects[1] = "<< /Type /Catalog /Pages 2 0 R >>\n"
    objects[2] = "<< /Type /Pages /Kids [#{kids}] /Count #{images.size} >>\n"

    out = +"%PDF-1.4\n".b
    offsets = [ 0 ]
    (1...objects.size).each do |num|
      offsets[num] = out.bytesize
      out << "#{num} 0 obj\n".b << objects[num] << "endobj\n".b
    end
    xref = out.bytesize
    out << "xref\n0 #{objects.size}\n"
    out << "0000000000 65535 f \n"
    (1...objects.size).each do |num|
      out << format("%010d 00000 n \n", offsets[num])
    end
    out << "trailer << /Size #{objects.size} /Root 1 0 R >>\nstartxref\n#{xref}\n%%EOF\n"
    out
  end

  private

  def pdf_stream(data)
    "<< /Length #{data.bytesize} >>\nstream\n".b + data + "endstream\n".b
  end
end
