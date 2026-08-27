module LegacyImport
  class CustomerImporter
    Result = Struct.new(:imported, :skipped_duplicates, :skipped_invalid, keyword_init: true)

    CPF_WEIGHTS_1 = (10).downto(2).to_a
    CPF_WEIGHTS_2 = (11).downto(2).to_a
    CNPJ_WEIGHTS_1 = [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]
    CNPJ_WEIGHTS_2 = [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]

    def self.call(pessoa_path:)
      new(pessoa_path).call
    end

    def initialize(pessoa_path)
      @pessoa_path = pessoa_path
    end

    def call
      pessoas = SqlDumpParser.call(@pessoa_path).fetch("pessoa").rows
      existing_legacy_ids = Set.new(Customer.pluck(:legacy_id))
      existing_documents = Set.new(Customer.pluck(:document))
      existing_codes = Set.new(Customer.pluck(:customer_code).compact)

      imported = 0
      skipped_duplicates = 0
      skipped_invalid = []
      batch = []
      batch_size = 1000

      pessoas.each do |row|
        legacy_id = row["id"].to_i

        if existing_legacy_ids.include?(legacy_id)
          skipped_duplicates += 1
          next
        end

        # Clean and combine names
        nome = (row["nome"] || "").strip
        sobrenome = (row["sobrenome"] || "").strip
        name = [ nome, sobrenome ].reject(&:empty?).join(" ")

        if name.blank?
          skipped_invalid << { legacy_id:, reason: "Nome vazio" }
          next
        end

        # Use CPF if available, otherwise CNPJ, or empty string for legacy data
        raw_document = (row["cpf"] || row["cnpj"] || "").to_s.strip
        # Clean document: remove formatting characters
        document = raw_document.gsub(/[^\d]/, "")
        tags = []

        # Validate and fix invalid documents
        if document.present? && !valid_document?(document)
          document = generate_valid_cpf
          tags << "invalid document"
          tags << "invalid data"
        elsif existing_documents.include?(document)
          # Document already exists, generate a new one
          document = generate_valid_cpf
          tags << "duplicate document"
          tags << "invalid data"
        end

        membership_number = row["numeroMatricula"]&.to_i

        batch << {
          name:,
          document:,
          membership_number:,
          customer_code: generate_customer_code(existing_codes),
          legacy_id:,
          tags:,
          created_at: Time.current,
          updated_at: Time.current
        }

        if batch.size >= batch_size
          imported += batch.size
          insert_customer_batch(batch)
          existing_documents.merge(batch.map { |b| b[:document] })
          batch = []
        end
      rescue StandardError => e
        skipped_invalid << { legacy_id:, reason: e.message }
      end

      # Insert remaining batch
      if batch.any?
        imported += batch.size
        insert_customer_batch(batch)
      end

      Result.new(imported:, skipped_duplicates:, skipped_invalid:)
end

    private

    def valid_document?(digits)
      digits = digits.to_s.strip

      case digits.length
      when 11
        valid_cpf?(digits)
      when 14
        valid_cnpj?(digits)
      else
        false
      end
    end

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

    def generate_valid_cpf
      base = 9.times.map { rand(0..9) }.join
      first_check = check_digit(base, CPF_WEIGHTS_1)
      second_check = check_digit(base + first_check.to_s, CPF_WEIGHTS_2)
      "#{base}#{first_check}#{second_check}"
    end

    # insert_all bypasses Customer's before_validation callback that would
    # normally generate this, so it has to be filled in here — same
    # algorithm, tracked against both pre-existing and just-generated codes.
    def generate_customer_code(existing_codes)
      loop do
        code = format("%06d", rand(1_000_000))
        next if existing_codes.include?(code)

        existing_codes << code
        break code
      end
    end

    # insert_all also bypasses Customer's after_create callback that would
    # normally provision the linked User (the customer's login) — so it's
    # done here too, in bulk, reusing the customer_code as the password.
    def insert_customer_batch(batch)
      inserted = Customer.insert_all(batch, returning: %w[id name document customer_code])

      now = Time.current
      users = inserted.to_a.map do |row|
        {
          name: row["name"],
          username: row["document"],
          password_digest: BCrypt::Password.create(row["customer_code"]),
          role: "customer",
          customer_id: row["id"],
          created_at: now,
          updated_at: now
        }
      end

      User.insert_all(users) if users.any?
    end
  end
end
