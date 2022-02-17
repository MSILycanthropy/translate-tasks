require "./helpers/parser_helper"

module ActionParser
  def self.parse
    p = Parser.new
    p.perform
  end

  private class Parser
    include ParserHelper
    @parser : OptionParser = OptionParser.new
    @config : Config = Config.new("#{Dir.current}/translate-tasks.yml")

    def perform
      @parser.banner = "idk what to put here yet"
      setup_flags
      setup_commands
      catch_error

      @parser.parse
    end

    private def setup_commands
      @parser.on("init", "Initialize a new project") do
        initialize_config
        exit
      end
      @parser.on("missing", "Show missing translations") do
        show_missing_translations
        exit
      end
      @parser.on("add missing", "Add missing translations") do
        #add_missing_translations
        puts "Not implemented yet"
        exit
      end
      @parser.on("unused", "Show unused translations") do
        show_unused_translations
        exit
      end
      @parser.on("add unused", "Add unused translations") do
        #add_unused_translations
        puts "Not implemented yet"
        exit
      end
    end

    private def setup_flags
      # TODO: do a version flag ig
      @parser.on "-h", "--help", "Show help" do
        puts @parser
        exit
      end
    end

    private def catch_error
      @parser.missing_option do |option_flag|
        @parser.banner = "THERE WAS AN ERROR GAMER"
        STDERR.puts "ERROR: #{option_flag} is missing something."
        STDERR.puts ""
        STDERR.puts @parser
        exit(1)
      end
      @parser.invalid_option do |option_flag|
        @parser.banner = "THERE WAS AN ERROR GAMER"
        STDERR.puts "ERROR: #{option_flag} is not a valid option."
        STDERR.puts @parser
        exit(1)
      end
    end
  end
end
