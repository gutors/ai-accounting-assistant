module NfeAccessKey
  UF = %w[11 12 13 14 15 16 17 21 22 23 24 25 26 27 28 29 31 32 33 35 41 42 43 50 51 52 53].freeze
  MODELS = %w[55 65 57 66 67].freeze
  HOST_UF = {
    "sefaz.rs.gov.br" => "43"
  }.freeze

  module_function

  def digits(text)
    return if text.blank?

    exact(text) || grouped(text) || assemble_nfce(text)
  end

  def exact(text)
    text.each_line do |line|
      run = line.gsub(/\D/, "")
      return run if run.length == 44
    end
    run = text.gsub(/\D/, "")
    return run if run.length == 44

    text[/\d{44}/]
  end
  private_class_method :exact

  def grouped(text)
    text.scan(/(?:\d{4}[\s.\/-]*){10}\d{4}/).each do |raw|
      run = raw.gsub(/\D/, "")
      return run if run.length == 44
    end
    nil
  end
  private_class_method :grouped

  def assemble_nfce(text)
    return unless text.match?(/consumidor|nfc-?e|chave de acesso/i)

    uf = uf_from(text)
    aamm = aamm_from(text)
    model = text.match?(/consumidor/i) ? "65" : "55"
    nnf = nfce_number(text)
    series = serie_candidates(text)
    cnpjs = cnpj_candidates(text)
    tail = tail10(text)
    probe = chave_probe(text)
    return if uf.blank? || aamm.blank? || nnf.blank? || tail.blank? || cnpjs.empty? || series.empty?

    hits = cnpjs.product(series).filter_map { |cnpj, serie|
      candidate = "#{uf}#{aamm}#{cnpj}#{model}#{serie}#{nnf}#{tail}"
      next unless candidate.length == 44
      next unless MODELS.include?(candidate[20, 2])
      next unless check_digit(candidate) == candidate[43].to_i

      candidate
    }
    return if hits.empty?

    hits.max_by { |candidate| match_score(candidate, probe) }
  end
  private_class_method :assemble_nfce

  def uf_from(text)
    HOST_UF.each { |host, uf| return uf if text.downcase.include?(host) }

    probe = chave_probe(text)[0, 2]
    probe if UF.include?(probe)
  end
  private_class_method :uf_from

  def aamm_from(text)
    match = text.match(%r{(\d{2})/(\d{2})/(\d{4})})
    return unless match

    "#{match[3][2, 2]}#{match[2]}"
  end
  private_class_method :aamm_from

  def nfce_number(text)
    match = text.match(/(?:nfc-?e|nfce|hfc-e)\D{0,24}(\d{5,12})/i)
    return unless match

    match[1].rjust(9, "0")[-9, 9]
  end
  private_class_method :nfce_number

  def serie_candidates(text)
    match = text.match(/s[eé]rie\D{0,8}(\d{1,3})/i)
    return [] unless match

    serie = match[1].rjust(3, "0")[-3, 3]
    [ serie, serie.sub(/\A8/, "0") ].uniq
  end
  private_class_method :serie_candidates

  def cnpj_candidates(text)
    found = []
    text.scan(/\d{2}[.\s]?\d{3}[.\s]?\d{3}[\/.\s]?\d{4}[-\s=]?\d{2}/).each do |raw|
      base = raw.gsub(/\D/, "")
      found.concat(cnpj_variants(base[0, 14])) if base.length >= 14
    end
    text.each_line do |line|
      run = line.gsub(/\D/, "")
      next unless run.length.between?(14, 16)

      (0..(run.length - 14)).each do |offset|
        found.concat(cnpj_variants(run[offset, 14]))
      end
    end
    found.uniq
  end
  private_class_method :cnpj_candidates

  def cnpj_variants(base)
    variants = [ base ]
    14.times do |index|
      %w[4 9 0 8].each do |digit|
        next if base[index] == digit

        trial = base.dup
        trial[index] = digit
        variants << trial
      end
    end
    variants.select { |digits| BrazilianTaxId.cnpj?(digits) }
  end
  private_class_method :cnpj_variants

  def tail10(text)
    groups = chave_groups(text)
    return if groups.size < 3

    joined = groups.last(3).join
    return joined[2, 10] if joined.length == 12
    return joined if joined.length == 10

    nil
  end
  private_class_method :tail10

  def chave_groups(text)
    line = text.each_line.max_by { |row| row.scan(/\d{4}/).size }.to_s
    line.scan(/\d{3,4}/)
  end
  private_class_method :chave_groups

  def chave_probe(text)
    chave_groups(text).join
  end
  private_class_method :chave_probe

  def match_score(candidate, probe)
    n = [ candidate.length, probe.length ].min
    n.times.count { |i| candidate[i] == probe[i] }
  end
  private_class_method :match_score

  def check_digit(digits)
    weights = [ 2, 3, 4, 5, 6, 7, 8, 9 ]
    sum = 0
    digits[0, 43].chars.reverse.each_with_index do |char, index|
      sum += char.to_i * weights[index % 8]
    end
    mod = sum % 11
    mod <= 1 ? 0 : 11 - mod
  end
  private_class_method :check_digit
end
