class SupportingDocument
  module BatchIdentify
    def identify_threads
      raw = ENV["IDENTIFY_THREADS"]
      n = raw.nil? ? IDENTIFY_THREADS_DEFAULT : Integer(raw, exception: false)
      n = IDENTIFY_THREADS_DEFAULT if n.nil?
      n.clamp(IDENTIFY_THREADS_MIN, IDENTIFY_THREADS_MAX)
    end

    def identify_batch(organization:, files:)
      list = Array(files)
      return [] if list.empty?

      size = [ list.size, identify_threads ].min
      items = Array.new(list.size)
      failures = Queue.new
      pool = Concurrent::FixedThreadPool.new(size)
      list.each_with_index do |file, index|
        pool.post do
          ActiveRecord::Base.connection_pool.with_connection do
            items[index] = identify_preview(organization, file)
          end
        rescue => error
          failures << error
        end
      end
      pool.shutdown
      pool.wait_for_termination
      raise failures.pop unless failures.empty?

      items
    end

    def identify_preview(organization, file)
      filename = file.respond_to?(:original_filename) ? file.original_filename.to_s : ""
      doc = identify(organization: organization, file: file)
      if doc.errors.any?
        { filename: filename, ok: false, error: doc.errors[:base].first }
      else
        {
          filename: filename,
          ok: true,
          error: nil,
          arquivo: doc.intake_arquivo,
          kind: doc.kind,
          amount: book_amount(doc.amount_cents),
          date: doc.document_on&.strftime("%Y-%m-%d").to_s,
          payee: doc.payee.to_s,
          chave: doc.chave.to_s,
          origin: doc.origin_stamp,
          locked: doc.fields_locked?
        }
      end
    end

    def book_amount(cents)
      return "" if cents.blank? || cents == 0

      whole, frac = cents.abs.divmod(100)
      grouped = whole.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
      "#{grouped},#{format("%02d", frac)}"
    end
  end
end
