module LegacyImport
  class SqlDumpParser
    Table = Struct.new(:name, :columns, :rows)

    def self.call(path_or_io)
      content = if path_or_io.is_a?(String)
                  File.read(path_or_io, encoding: "UTF-8")
      else
                  path_or_io.read
      end

      new(content).parse
    end

    def initialize(content)
      @content = content
      @tables = {}
    end

    def parse
      # Find all CREATE TABLE ... blocks and their corresponding INSERT statements
      create_table_pattern = /CREATE\s+TABLE\s+`(\w+)`\s*\((.*?)\)\s*(?:;|\n)/m
      insert_pattern = /INSERT\s+INTO\s+`(\w+)`\s+VALUES\s+(.*?);/m

      @content.scan(create_table_pattern) do |table_name, column_defs|
        columns = extract_columns(column_defs)
        @tables[table_name] = Table.new(table_name, columns, [])
      end

      @content.scan(insert_pattern) do |table_name, values_block|
        next unless @tables[table_name]

        rows = parse_rows(values_block, @tables[table_name].columns)
        @tables[table_name].rows.concat(rows)
      end

      @tables
    end

    private

    def extract_columns(column_defs)
      columns = []
      constraint_names = Set.new

      # Collect constraint/key names to exclude later
      # PRIMARY KEY (`id`), KEY `idx_name` (`name`), CONSTRAINT `fk_ref` FOREIGN KEY...
      column_defs.scan(/CONSTRAINT\s+`([^`]+)`/) do |match|
        constraint_names.add(match[0])
      end
      column_defs.scan(/KEY\s+`([^`]+)`\s*\(/) do |match|
        constraint_names.add(match[0])
      end

      # Find all backtick-quoted identifiers that look like column definitions
      # (followed by a space and then a type keyword or closing paren)
      column_defs.scan(/`([\w-]+)`\s+(?=\w|\)|,)/) do |match|
        col_name = match[0]
        columns << col_name unless constraint_names.include?(col_name)
      end

      columns
    end

    def parse_rows(values_block, columns)
      rows = []
      current_row = []
      current_value = ""
      in_string = false
      escape_next = false
      paren_depth = 0
      value_was_string = false

      values_block.each_char do |char|
        if escape_next
          current_value += char
          escape_next = false
          next
        end

        if char == "\\" && in_string
          escape_next = true
          current_value += char
        elsif char == "'" && in_string
          in_string = false
        elsif char == "'" && !in_string && (current_value.empty? || current_value.match?(/^\s*$/))
          in_string = true
          value_was_string = true
          current_value = ""
        elsif char == "(" && !in_string
          paren_depth += 1
          current_value = ""
          value_was_string = false
        elsif char == ")" && !in_string && paren_depth > 0
          paren_depth -= 1
          if paren_depth == 0
            val = value_was_string ? "'#{current_value.strip}'" : current_value.strip
            current_row << parse_value(val, value_was_string)
            rows << Hash[columns.zip(current_row)] if current_row.length == columns.length
            current_row = []
            current_value = ""
            value_was_string = false
          end
        elsif char == "," && !in_string && paren_depth > 0
          val = value_was_string ? "'#{current_value.strip}'" : current_value.strip
          current_row << parse_value(val, value_was_string)
          current_value = ""
          value_was_string = false
        else
          current_value += char if paren_depth > 0
        end
      end

      rows
    end

    def parse_value(value_str, was_string = false)
      return nil if value_str == "NULL" && !was_string
      return "" if value_str.empty? && was_string
      return "" if value_str == "''"

      if value_str.start_with?("'") && value_str.end_with?("'")
        unescaped = value_str[1..-2]
        unescaped.gsub("\\\\", "\x00").gsub("\\'", "'").gsub("\x00", "\\")
      else
        value_str
      end
    end
  end
end
