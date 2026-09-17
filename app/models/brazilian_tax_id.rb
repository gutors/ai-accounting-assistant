module BrazilianTaxId
  module_function

  def normalize(value)
    value.to_s.gsub(/\D/, "").presence
  end

  def valid?(digits)
    cpf?(digits) || cnpj?(digits)
  end

  def cpf?(digits)
    numbers = digits.to_s.chars.map(&:to_i)
    return false if numbers.size != 11 || numbers.uniq.size == 1

    numbers[9] == check_digit(numbers[0, 9], (2..10).to_a.reverse) &&
      numbers[10] == check_digit(numbers[0, 10], (2..11).to_a.reverse)
  end

  def format(digits)
    numbers = digits.to_s
    if cnpj?(numbers)
      "#{numbers[0, 2]}.#{numbers[2, 3]}.#{numbers[5, 3]}/#{numbers[8, 4]}-#{numbers[12, 2]}"
    elsif cpf?(numbers)
      "#{numbers[0, 3]}.#{numbers[3, 3]}.#{numbers[6, 3]}-#{numbers[9, 2]}"
    end
  end

  def cnpj?(digits)
    numbers = digits.to_s.chars.map(&:to_i)
    return false if numbers.size != 14 || numbers.uniq.size == 1

    numbers[12] == check_digit(numbers[0, 12], [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]) &&
      numbers[13] == check_digit(numbers[0, 13], [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ])
  end

  def check_digit(numbers, weights)
    sum = numbers.each_with_index.sum { |number, index| number * weights[index] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
  private_class_method :check_digit
end
