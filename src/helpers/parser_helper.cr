
module ParserHelper
  def initialize_config
    directory = Dir.current

    if File.exists?("#{directory}/translate-tasks.yml")
      STDERR.puts "translate-tasks.yml already exists"
      return
    end

    File.open("#{directory}/translate-tasks.yml", "w") do |file|
      file << default_yaml
    end
  end

  def show_missing_translations
    table = TerminalTable.new
    table.headings = ["Locale", "Key"]
    table.separate_rows = true

    @config.keys.each do |key|
      read_directory = if @config.read(key).directory == "root"
                         Dir.current
                       else
                         "#{Dir.current}/#{@config.read(key).directory}"
                       end
      write_directory = if @config.write(key).directory == "root"
                          Dir.current
                        else
                          "#{Dir.current}/#{@config.write(key).directory}"
                        end
      scanned = Scanner.new(read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

      @config.locales(key).as(Array).each do |locale|
        yaml = YAML.parse(File.read("#{write_directory}/#{locale}.yml"))
        yaml_tree = Tree.from_yaml(yaml)

        scanned_tree = Tree.from_scanned_results(scanned, locale.as(String))
        missing_keys = scanned_tree.missing(yaml_tree).map { |missing| missing.full_name }

        missing_keys.each do |key|
          table << [locale.colorize(:yellow).to_s, key.colorize(:red).to_s]
        end
      end
    end

    puts table.render
  end

  def show_unused_translations
    table = TerminalTable.new
    table.headings = ["Locale", "Key"]
    table.separate_rows = true

    @config.keys.each do |key|
      read_directory = if @config.read(key).directory == "root"
                         Dir.current
                       else
                         "#{Dir.current}/#{@config.read(key).directory}"
                       end
      write_directory = if @config.write(key).directory == "root"
                          Dir.current
                        else
                          "#{Dir.current}/#{@config.write(key).directory}"
                        end
      scanned = Scanner.new(read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

      @config.locales(key).as(Array).each do |locale|
        yaml = YAML.parse(File.read("#{write_directory}/#{locale}.yml"))
        yaml_tree = Tree.from_yaml(yaml)

        scanned_tree = Tree.from_scanned_results(scanned, locale.as(String))
        missing_keys = scanned_tree.unused(yaml_tree).map { |missing| missing.full_name }

        missing_keys.each do |key|
          table << [locale.colorize(:yellow).to_s, key.colorize(:red).to_s]
        end
      end
    end

    puts table.render
  end

  private def default_yaml
    <<-END
    ---
    settings_keys:
      - name_one

    # allow for subsettings per directory
    # each one should ignore the files in the other
    name_one:
      base_locale: en
      locales:
        - bn
        - de
        - en
        - eo
        - es
        - fr
        - hi
        - it
        - ja
        - jv
        - ko
        - pt
        - zh
      read:
        directory: root
        #exclude: spec/*
        file_types:
          - "*.rb"
      write:
        directory: root
        single_file: false
        # ignore_missing:
        # ignore_unused:
    # whereas this looks for example/components/button/locales.yml
    # name_two:
    #   base_locale: en
    #   locales:
    #     - bn
    #     - de
    #     - en
    #   read:
    #     directory: example/directory/read
    #     exclude: example/directory/exclude
    #   write:
    #     single_file: true
    #     file_name: locales
    #     directory: example/directory/write
    # ignore_missing:
    # ignore_unused:
    END
  end
end
