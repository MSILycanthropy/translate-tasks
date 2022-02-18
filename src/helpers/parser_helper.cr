
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
    @config.keys.each do |key|
      missing_keys_hash = {} of String => Array(String)
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
        missing_keys = scanned_tree.missing(yaml_tree).map { |missing| missing.full_name.gsub("#{locale}.", "") }
        ignored = ignored_keys(@config.write(key).ignore_missing, missing_keys)
        missing_keys_hash[locale] = (missing_keys - ignored).reject! { |key| key.includes?("\#{") }
      end

      render_table(missing_keys_hash, "Missing Keys", @config.locales(key).as(Array))
    end
  end

  def show_unused_translations
    @config.keys.each do |key|
      unused_keys_hash = {} of String => Array(String)
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
      scanned = scanned.reject { |key| key.includes?("\#{") }.to_set

      @config.locales(key).as(Array).each do |locale|
        yaml = YAML.parse(File.read("#{write_directory}/#{locale}.yml"))
        yaml_tree = Tree.from_yaml(yaml)
        scanned_tree = Tree.from_scanned_results(scanned, locale.as(String))
        unused_keys = scanned_tree.unused(yaml_tree).map { |unused| unused.full_name.gsub("#{locale}.", "") }

        ignored = ignored_keys(@config.write(key).ignore_unused, unused_keys)

        unused_keys_hash[locale] = (unused_keys - ignored).reject! { |key| key.includes?("\#{") }
      end

     render_table(unused_keys_hash, "Unused Keys", @config.locales(key).as(Array))
    end
  end

  private def render_table(keys_hash : Hash(String, Array(String)), title : String, locales : Array(String))
    table = TerminalTable.new
    table.headings = ["Locale", "Key"]

    if keys_hash.keys == locales
      all = "all".colorize(:blue).to_s
      keys_hash[locales.first].each do |key|
        table << [all, key.colorize(:green).to_s]
      end
    else
      keys_hash.each do |locale, keys|
        keys.each do |key|
          table << [locale.colorize(:blue).to_s, key.colorize(:green).to_s]
        end
      end
    end



    if table.rows.size > 0
      puts title
      puts table.render
    else
      puts "Congrats! No #{title.downcase} found".colorize(:green)
    end
  end

  private def ignored_keys(ignored : Array(String) | Nil, array : Array(String)) : Array(String)
    return [] of String if ignored.nil?

    filter = [] of String

    ignored.each do |key|
      if key.includes?("*")
        filter.concat(array.select { |array_key| array_key.starts_with?(key.gsub("*", "")) })
      elsif key.includes?("{")
        parts_to_insert = key.scan(/{.+}/).first[0].strip("{}").split(",")
        parts_to_insert.each do |part|
          filter << key.gsub(/{.+}/, part)
        end
      elsif array.includes?(key)
        filter << key
      end
    end

    filter
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
