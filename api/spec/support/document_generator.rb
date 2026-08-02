module DocumentGenerator
  module_function

  def cpf(base)
    digits = base.to_s.rjust(9, "0")
    d1 = check_digit(digits, (10).downto(2).to_a)
    d2 = check_digit(digits + d1.to_s, (11).downto(2).to_a)
    "#{digits}#{d1}#{d2}"
  end

  def cnpj(base)
    digits = base.to_s.rjust(12, "0")
    d1 = check_digit(digits, [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ])
    d2 = check_digit(digits + d1.to_s, [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ])
    "#{digits}#{d1}#{d2}"
  end

  def check_digit(digits, weights)
    sum = digits.chars.each_with_index.sum { |d, i| d.to_i * weights[i] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
