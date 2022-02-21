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
    @gif_printer = GifPrinter.new
    @translator = Translator.new
    @locales : Array(String) = [] of String
    @command : Symbol = :help
    @gif : Bool = false
    @yes : Bool = false
    @read_directory : String = ""
    @write_directory : String = ""
    @yaml_forest = {} of String => Tree
    @scanned_forest = {} of String => Tree

    def initialize
      setup_flags
      setup_commands
      catch_error
    end

    def perform
      @parser.banner = "idk what to put here yet"
      @parser.parse

      # TODO: Abstract this into a lookup of functions
      case @command
      when :initialize
        initialize_config
      when :missing
        deny_no_config!
        @config.keys.each do |key|
          set_context(key)
          missing_translations = missing_translations(key)

          render_table(missing_translations, "Missing Translations", @config.locales(key))
        end
      when :unused
        deny_no_config!
        @config.keys.each do |key|
          set_context(key)
          unused_translations = unused_translations(key)

          render_table(unused_translations, "Unused Translations", @config.locales(key))
        end
      when :add_missing
        deny_no_config!
        @config.keys.each do |key|
          set_context(key)
          missing_translations = missing_translations(key)

          render_table(missing_translations, "Missing Translations", @config.locales(key))

          unless missing_translations.all? { |_, v| v.empty? }
            if @yes
              should_add = "y"
            else
              print "Would you like to add the above keys (y/n)? "
              should_add = gets
            end

            if should_add
              if should_add.chomp == "y"
                add_missing_translations(key, missing_translations)
                gracefully_exit(:success)
              else
                gracefully_exit(:failure)
              end
            else
              exit
            end
          end
        end
      when :translate_missing
        deny_no_config!
        @config.keys.each do |key|
          set_context(key)
          missing_translations = missing_translations(key)

          render_table(missing_translations, "Missing Translations", @config.locales(key))

          unless missing_translations.all? { |_, v| v.empty? }
            if @yes
              should_translate = "y"
            else
              print "Would you like to translate the above keys (y/n)? "
              should_translate = gets
            end

            if should_translate
              if should_translate.chomp == "y"
                translate_missing_translations(key, missing_translations, @config.base_locale(key))
                gracefully_exit(:success)
              else
                gracefully_exit(:failure)
              end
            else
              exit
            end
          end
        end
      when :remove_unused
        deny_no_config!
        @config.keys.each do |key|
          set_context(key)
          unused_translations = unused_translations(key)

          render_table(unused_translations, "Unused Translations", @config.locales(key))

          unless unused_translations.all? { |_, v| v.empty? }
            if @yes
              should_remove = "y"
            else
              print "Would you like to remove the above keys (y/n)? "
              should_remove = gets
            end

            if should_remove
              if should_remove.chomp == "y"
                remove_unused_translations(key, unused_translations)
                gracefully_exit(:success)
              else
                gracefully_exit(:failure)
              end
            else
              exit
            end
          end
        end
      when :normalize
        deny_no_config!
        @config.keys.each do |key|
          normalize_translations(key)
        end
        gracefully_exit(:success)
      when :gif
        @gif_printer.print([:success, :failure].shuffle.first)
      end
    end

    private def setup_commands
      @parser.on("init", "Initialize a new project") do
        @command = :initialize
      end
      @parser.on("missing", "Show missing translations") do
        @command = :missing
      end
      @parser.on("add-missing", "Add missing translations") do
        @command = :add_missing
      end
      @parser.on("translate-missing", "Translate missing translations") do
        @command = :translate_missing
      end
      @parser.on("unused", "Show unused translations") do
        @command = :unused
      end
      @parser.on("remove-unused", "Remove unused translations") do
        @command = :remove_unused
      end
      @parser.on("normalize", "Normalize translations") do
        @command = :normalize
      end
      @parser.on("gif", "Render a random gif") do
        @command = :gif
      end
    end

    def gracefully_exit(type : Symbol)
      send_gif = @gif || rand(100) == 1

      if type == :success
        puts "All done!"
        puts "Here's a gif because... why not?" if send_gif
      elsif
        puts "Well, that didn't quite work... "
        puts "Bye!"
      end

      @gif_printer.print(type) if send_gif
      exit
    end

    private def set_context(key)
      @read_directory = if @config.read(key).directory == "root"
                          Dir.current
                        else
                          "#{Dir.current}/#{@config.read(key).directory}"
                        end
      @write_directory = if @config.write(key).directory == "root"
                           Dir.current
                         else
                           "#{Dir.current}/#{@config.write(key).directory}"
                         end
      @locales = @config.locales(key) if @locales.empty?
    end

    private def deny_no_config!
      unless @config.exists?
        puts "Config file not found. Please create one with translate-tasks init"
        exit
      end
    end

    private def setup_flags
      # TODO: do a version flag ig
      @parser.on "-h", "--help", "Show help" do
        puts @parser
        exit
      end
      @parser.on("-l LOCALE", "--locale=LOCALE", "Locale to check") do |locale|
        @locales << locale
      end
      @parser.on("-g", "--gif", "Show the cool random gifs every time") do
        @gif = true
      end
      @parser.on("-y", "--yes", "Automatically answer yes to prompts") do
        @yes = true
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
