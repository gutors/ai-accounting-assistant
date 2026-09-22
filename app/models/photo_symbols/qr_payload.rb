# frozen_string_literal: true

module PhotoSymbols
  class QrPayload
    MASKS = [
      ->(i, j) { (i + j).even? },
      ->(i, j) { i.even? },
      ->(i, j) { (j % 3).zero? },
      ->(i, j) { ((i + j) % 3).zero? },
      ->(i, j) { ((i / 2) + (j / 3)).even? },
      ->(i, j) { ((i * j) % 2) + ((i * j) % 3) == 0 },
      ->(i, j) { (((i * j) % 2) + ((i * j) % 3)).even? },
      ->(i, j) { (((i + j) % 2) + ((i * j) % 3)).even? }
    ].freeze

    ALIGNMENT = [
      [],
      [ 6, 18 ], [ 6, 22 ], [ 6, 26 ], [ 6, 30 ], [ 6, 34 ],
      [ 6, 22, 38 ], [ 6, 24, 42 ], [ 6, 26, 46 ], [ 6, 28, 50 ], [ 6, 30, 54 ],
      [ 6, 32, 58 ], [ 6, 34, 62 ], [ 6, 26, 46, 66 ], [ 6, 26, 48, 70 ],
      [ 6, 26, 50, 74 ], [ 6, 30, 54, 78 ], [ 6, 30, 56, 82 ], [ 6, 30, 58, 86 ],
      [ 6, 34, 62, 90 ]
    ].freeze

    # [count, total, data] groups per version, order L M Q H
    RS_BLOCKS = {
      1 => [ [ 1, 26, 19 ], [ 1, 26, 16 ], [ 1, 26, 13 ], [ 1, 26, 9 ] ],
      2 => [ [ 1, 44, 34 ], [ 1, 44, 28 ], [ 1, 44, 22 ], [ 1, 44, 16 ] ],
      3 => [ [ 1, 70, 55 ], [ 1, 70, 44 ], [ 2, 35, 17 ], [ 2, 35, 13 ] ],
      4 => [ [ 1, 100, 80 ], [ 2, 50, 32 ], [ 2, 50, 24 ], [ 4, 25, 9 ] ],
      5 => [ [ 1, 134, 108 ], [ 2, 67, 43 ], [ 2, 33, 15, 2, 34, 16 ], [ 2, 33, 11, 2, 34, 12 ] ],
      6 => [ [ 2, 86, 68 ], [ 4, 43, 27 ], [ 4, 43, 19 ], [ 4, 43, 15 ] ],
      7 => [ [ 2, 98, 78 ], [ 4, 49, 31 ], [ 2, 32, 14, 4, 33, 15 ], [ 4, 39, 13, 1, 40, 14 ] ],
      8 => [ [ 2, 121, 97 ], [ 2, 60, 38, 2, 61, 39 ], [ 4, 40, 18, 2, 41, 19 ], [ 4, 40, 14, 2, 41, 15 ] ],
      9 => [ [ 2, 146, 116 ], [ 3, 58, 36, 2, 59, 37 ], [ 4, 36, 16, 4, 37, 17 ], [ 4, 36, 12, 4, 37, 13 ] ],
      10 => [ [ 2, 86, 68, 2, 87, 69 ], [ 4, 69, 43, 1, 70, 44 ], [ 6, 43, 19, 2, 44, 20 ], [ 6, 43, 15, 2, 44, 16 ] ]
    }.freeze

    EC_INDEX = { 1 => 0, 0 => 1, 3 => 2, 2 => 3 }.freeze

    def self.decode(modules)
      size = modules.size
      version = (size - 17) / 4
      return unless version.between?(1, 10)

      format = read_format(modules)
      return unless format

      ec_bits, mask = format
      ec_index = EC_INDEX[ec_bits]
      return unless ec_index

      reserved = reserved_mask(size, version)
      bits = read_bits(modules, mask, reserved)
      data_bytes = deinterleave(bits, version, ec_index)
      parse(data_bytes, version)
    end

    def self.read_format(modules)
      bits = 0
      6.times { |i| bits = (bits << 1) | (modules[8][i] ? 1 : 0) }
      bits = (bits << 1) | (modules[8][7] ? 1 : 0)
      bits = (bits << 1) | (modules[8][8] ? 1 : 0)
      bits = (bits << 1) | (modules[7][8] ? 1 : 0)
      5.downto(0) { |i| bits = (bits << 1) | (modules[i][8] ? 1 : 0) }
      bits ^= 0b101010000010010
      [ (bits >> 13) & 0b11, (bits >> 10) & 0b111 ]
    end
    private_class_method :read_format

    def self.reserved_mask(size, version)
      reserved = Array.new(size) { Array.new(size, false) }
      mark_finder = lambda do |x, y|
        (0..7).each do |dy|
          (0..7).each do |dx|
            xx = x + dx
            yy = y + dy
            next if xx.negative? || yy.negative? || xx >= size || yy >= size

            reserved[yy][xx] = true
          end
        end
      end
      mark_finder.call(0, 0)
      mark_finder.call(size - 8, 0)
      mark_finder.call(0, size - 8)
      size.times do |i|
        reserved[6][i] = true
        reserved[i][6] = true
      end
      6.times do |i|
        reserved[8][i] = true
        reserved[i][8] = true
      end
      reserved[8][7] = true
      reserved[8][8] = true
      reserved[7][8] = true
      8.times do |i|
        reserved[8][size - 8 + i] = true
        reserved[size - 1 - i][8] = true if i < 7
      end
      reserved[(4 * version) + 9][8] = true
      if version >= 7
        6.times do |i|
          3.times do |j|
            reserved[i][size - 11 + j] = true
            reserved[size - 11 + j][i] = true
          end
        end
      end
      positions = ALIGNMENT[version - 1] || []
      positions.product(positions).each do |x, y|
        next if (x < 9 && y < 9) || (x < 9 && y > size - 10) || (x > size - 10 && y < 9)

        (-2..2).each do |dy|
          (-2..2).each do |dx|
            reserved[y + dy][x + dx] = true
          end
        end
      end
      reserved
    end
    private_class_method :reserved_mask

    def self.read_bits(modules, mask, reserved)
      size = modules.size
      bits = []
      going_up = true
      x = size - 1
      while x > 0
        x -= 1 if x == 6
        size.times do |i|
          y = going_up ? (size - 1 - i) : i
          2.times do |dx|
            xx = x - dx
            next if reserved[y][xx]

            dark = modules[y][xx]
            dark = !dark if MASKS[mask].call(y, xx)
            bits << (dark ? 1 : 0)
          end
        end
        going_up = !going_up
        x -= 2
      end
      bits
    end
    private_class_method :read_bits

    def self.deinterleave(bits, version, ec_index)
      spec = RS_BLOCKS.dig(version, ec_index)
      return [] unless spec

      blocks = []
      spec.each_slice(3) do |count, total, data|
        count.times { blocks << { total:, data:, words: [] } }
      end
      bytes = bits.each_slice(8).filter_map { |slice| slice.size == 8 ? slice.join.to_i(2) : nil }
      max_total = blocks.map { |b| b[:total] }.max
      offset = 0
      max_total.times do |i|
        blocks.each do |block|
          next if i >= block[:total]

          block[:words] << bytes[offset]
          offset += 1
        end
      end
      blocks.flat_map { |block| block[:words].first(block[:data]) }
    end
    private_class_method :deinterleave

    def self.parse(data_bytes, version)
      bits = data_bytes.compact.flat_map { |byte| 8.times.map { |i| (byte >> (7 - i)) & 1 } }
      pos = 0
      take = lambda do |n|
        return if pos + n > bits.size

        value = 0
        n.times { value = (value << 1) | bits[pos]; pos += 1 }
        value
      end
      parts = []
      loop do
        mode = take.call(4)
        break if mode.nil? || mode.zero?

        case mode
        when 0b0100
          len_bits = version <= 9 ? 8 : 16
          length = take.call(len_bits)
          break unless length

          bytes = length.times.map { take.call(8) }
          break if bytes.any?(&:nil?)

          parts << bytes.pack("C*")
        when 0b0001
          len_bits = version <= 9 ? 10 : 12
          length = take.call(len_bits)
          break unless length

          chars = []
          groups, rem = length.divmod(3)
          groups.times do
            triple = take.call(10)
            break unless triple

            chars << format("%03d", triple)
          end
          if rem == 2
            pair = take.call(7)
            chars << format("%02d", pair) if pair
          elsif rem == 1
            one = take.call(4)
            chars << one.to_s if one
          end
          parts << chars.join
        when 0b0010
          len_bits = version <= 9 ? 9 : 11
          length = take.call(len_bits)
          break unless length

          alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
          chars = []
          pairs, rem = length.divmod(2)
          pairs.times do
            pair = take.call(11)
            break unless pair

            chars << alphabet[pair / 45] << alphabet[pair % 45]
          end
          if rem == 1
            one = take.call(6)
            chars << alphabet[one] if one
          end
          parts << chars.join
        else
          break
        end
      end
      parts.join.force_encoding("UTF-8")
    end
    private_class_method :parse
  end
end
