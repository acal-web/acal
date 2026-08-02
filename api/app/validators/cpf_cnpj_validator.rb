class CpfCnpjValidator < ActiveModel::EachValidator
  CPF_WEIGHTS_1 = (10).downto(2).to_a
  CPF_WEIGHTS_2 = (11).downto(2).to_a
  CNPJ_WEIGHTS_1 = [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]
  CNPJ_WEIGHTS_2 = [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]

  def validate_each(record, attribute, value)
    digits = value.to_s

    valid = case digits.length
    when 11 then valid_cpf?(digits)
    when 14 then valid_cnpj?(digits)
    else false
    end

    record.errors.add(attribute, :invalid) unless valid
  end

  private

  def valid_cpf?(digits)
    return false if digits.chars.uniq.one?

    check_digit(digits[0...9], CPF_WEIGHTS_1) == digits[9].to_i &&
      check_digit(digits[0...10], CPF_WEIGHTS_2) == digits[10].to_i
  end

  def valid_cnpj?(digits)
    return false if digits.chars.uniq.one?

    check_digit(digits[0...12], CNPJ_WEIGHTS_1) == digits[12].to_i &&
      check_digit(digits[0...13], CNPJ_WEIGHTS_2) == digits[13].to_i
  end

  def check_digit(digits, weights)
    sum = digits.chars.each_with_index.sum { |d, i| d.to_i * weights[i] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
