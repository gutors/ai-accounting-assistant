class MonthListSort
  def self.parse(sort, dir, columns:)
    s = sort.to_s
    d = dir.to_s
    return [ "date", "asc" ] unless columns.include?(s) && %w[asc desc].include?(d)

    [ s, d ]
  end

  def self.apply(records, sort, dir, date:, amount: :amount_cents, payee: nil)
    sorted = records.sort_by do |record|
      primary = case sort
      when "amount" then record.public_send(amount)
      when "payee" then record.public_send(payee).to_s
      else record.public_send(date)
      end
      [ primary, record.id ]
    end
    dir == "desc" ? sorted.reverse : sorted
  end
end
