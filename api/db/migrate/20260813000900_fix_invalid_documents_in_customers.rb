class FixInvalidDocumentsInCustomers < ActiveRecord::Migration[8.1]
  CPF_WEIGHTS_1 = (10).downto(2).to_a
  CPF_WEIGHTS_2 = (11).downto(2).to_a

  def up
    customers = execute("SELECT id, document FROM customers").to_a

    customers.each do |customer|
      document = customer["document"]
      next if document.nil?

      unless valid_cpf?(document)
        new_cpf = generate_valid_cpf
        execute("UPDATE customers SET document = '#{new_cpf}', tags = tags || '[\"data error\"]'::jsonb WHERE id = '#{customer["id"]}'")
      end
    end
  end

  def down
    # This migration is not reversible as we've changed data
  end

  private

  def valid_cpf?(digits)
    digits = digits.to_s.strip
    return false if digits.length != 11
    return false if digits.chars.uniq.one?

    check_digit(digits[0...9], CPF_WEIGHTS_1) == digits[9].to_i &&
      check_digit(digits[0...10], CPF_WEIGHTS_2) == digits[10].to_i
  end

  def check_digit(digits, weights)
    sum = digits.chars.each_with_index.sum { |d, i| d.to_i * weights[i] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end

  def generate_valid_cpf
    # Gera 9 dígitos aleatórios
    base = 9.times.map { rand(0..9) }.join

    # Calcula o primeiro dígito verificador
    first_check = check_digit(base, CPF_WEIGHTS_1)

    # Calcula o segundo dígito verificador
    second_check = check_digit(base + first_check.to_s, CPF_WEIGHTS_2)

    "#{base}#{first_check}#{second_check}"
  end
end
