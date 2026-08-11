require "rails_helper"

describe LegacyImport::SqlDumpParser do
  describe ".call" do
    context "parsing CREATE TABLE statements" do
      it "extracts column names in order, ignoring KEY and CONSTRAINT lines" do
        sql = <<~SQL
          CREATE TABLE `test` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(255) NOT NULL,
            `value` decimal(10,2),
            PRIMARY KEY (`id`),
            KEY `idx_name` (`name`),
            CONSTRAINT `fk_ref` FOREIGN KEY (`ref_id`) REFERENCES `other` (`id`)
          )
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        table = result["test"]

        expect(table.columns).to eq([ "id", "name", "value" ])
      end

      it "handles backtick-quoted column names" do
        sql = <<~SQL
          CREATE TABLE `test` (
            `id` int,
            `col-with-dash` varchar(100)
          )
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        expect(result["test"].columns).to eq([ "id", "col-with-dash" ])
      end
    end

    context "parsing INSERT INTO VALUES statements" do
      it "parses simple rows with strings, numbers, and NULL" do
        sql = <<~SQL
          CREATE TABLE `test` (
            `id` int,
            `name` varchar(100),
            `count` int,
            `active` varchar(50)
          );
          INSERT INTO `test` VALUES (1,'Alice',10,'yes'),(2,'Bob',20,NULL);
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows.length).to eq(2)
        expect(rows[0]).to eq({ "id" => "1", "name" => "Alice", "count" => "10", "active" => "yes" })
        expect(rows[1]).to eq({ "id" => "2", "name" => "Bob", "count" => "20", "active" => nil })
      end

      it "distinguishes NULL from empty string" do
        sql = <<~SQL
          CREATE TABLE `test` (`id` int, `value` varchar(100));
          INSERT INTO `test` VALUES (1,''),(2,NULL);
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["value"]).to eq("")
        expect(rows[1]["value"]).to be_nil
      end

      it "handles escaped single quotes inside string values" do
        sql = 'CREATE TABLE `test` (`id` int, `name` varchar(100));
INSERT INTO `test` VALUES (1,\'Sócio\\\'s name\'),(2,\'It\\\'s fine\');'

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["name"]).to eq("Sócio's name")
        expect(rows[1]["name"]).to eq("It's fine")
      end

      it "handles escaped backslashes" do
        sql = 'CREATE TABLE `test` (`id` int, `path` varchar(200));
INSERT INTO `test` VALUES (1,\'C:\\\\Users\\\\file\');'

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["path"]).to eq("C:\\Users\\file")
      end

      it "preserves literal newlines inside quoted string values" do
        sql = <<~SQL
          CREATE TABLE `test` (`id` int, `description` text);
          INSERT INTO `test` VALUES (1,'Line 1
          Line 2
          Line 3');
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["description"]).to include("Line 1")
        expect(rows[0]["description"]).to include("Line 2")
        expect(rows[0]["description"]).to include("Line 3")
      end

      it "handles decimal numbers without quotes" do
        sql = <<~SQL
          CREATE TABLE `test` (`id` int, `price` decimal(10,2), `quantity` int);
          INSERT INTO `test` VALUES (1,19.99,5),(2,0.01,100);
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["price"]).to eq("19.99")
        expect(rows[1]["price"]).to eq("0.01")
        expect(rows[1]["quantity"]).to eq("100")
      end

      it "handles negative numbers" do
        sql = <<~SQL
          CREATE TABLE `test` (`id` int, `balance` int);
          INSERT INTO `test` VALUES (1,-100),(2,-50);
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["balance"]).to eq("-100")
        expect(rows[1]["balance"]).to eq("-50")
      end

      it "handles multiple INSERT statements in one file" do
        sql = <<~SQL
          CREATE TABLE `users` (`id` int, `name` varchar(100));
          INSERT INTO `users` VALUES (1,'Alice'),(2,'Bob');

          CREATE TABLE `posts` (`id` int, `title` varchar(200));
          INSERT INTO `posts` VALUES (1,'First post'),(2,'Second');
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))

        expect(result["users"].rows.length).to eq(2)
        expect(result["posts"].rows.length).to eq(2)
        expect(result["users"].rows[0]["name"]).to eq("Alice")
        expect(result["posts"].rows[0]["title"]).to eq("First post")
      end

      it "handles rows with whitespace/commas inside string values" do
        sql = <<~SQL
          CREATE TABLE `test` (`id` int, `value` varchar(100));
          INSERT INTO `test` VALUES (1,'value, with, commas'),(2,'value with spaces');
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows[0]["value"]).to eq("value, with, commas")
        expect(rows[1]["value"]).to eq("value with spaces")
      end
    end

    context "with real mysqldump file format" do
      it "parses a realistic dump with comments, charset declarations, and LOCK/UNLOCK" do
        sql = <<~SQL
          /*!40101 SET NAMES utf8 */;
          /*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
          CREATE TABLE `test` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `nome` varchar(255),
            PRIMARY KEY (`id`)
          );
          LOCK TABLES `test` WRITE;
          INSERT INTO `test` VALUES (1,'First'),(2,'Second');
          UNLOCK TABLES;
        SQL

        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        rows = result["test"].rows

        expect(rows.length).to eq(2)
        expect(rows[0]["nome"]).to eq("First")
      end
    end

    context "error handling" do
      it "raises an error if file not found" do
        expect do
          LegacyImport::SqlDumpParser.call("/nonexistent/file.sql")
        end.to raise_error(Errno::ENOENT)
      end

      it "returns empty hash if no tables found" do
        sql = "-- Only comments here"
        result = LegacyImport::SqlDumpParser.call(StringIO.new(sql))
        expect(result).to eq({})
      end
    end
  end
end
