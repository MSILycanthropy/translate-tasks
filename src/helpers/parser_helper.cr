
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

  def missing_translations(key)
    missing_keys_hash = {} of String => Array(String)
    scanned = Scanner.new(@read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

    @locales.each do |locale|
      yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      yaml = nil unless yaml.as_h?

      if yaml.nil?
        missing_keys_hash[locale] = scanned.to_a
      else
        yaml_tree = Tree.from_yaml(yaml)
        scanned_tree = Tree.from_scanned_results(scanned, locale)

        missing_keys_hash[locale] = scanned_tree.missing_keys(yaml_tree, locale, @config.write(key).ignore_missing || [] of String)
      end
    end

    missing_keys_hash
  end

  def unused_translations(key)
    unused_keys_hash = {} of String => Array(String)
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
    scanned = Scanner.new(@read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

    @locales.each do |locale|
      yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      yaml = nil unless yaml.as_h?

      if yaml.nil?
        unused_keys_hash[locale] = scanned.to_a
      else
        yaml_tree = Tree.from_yaml(yaml)
        scanned_tree = Tree.from_scanned_results(scanned, locale.as(String))

        unused_keys_hash[locale] = scanned_tree.unused_keys(yaml_tree, locale, @config.write(key).ignore_unused || [] of String)
      end
    end

    unused_keys_hash
  end

  def add_missing_translations(key, missing_translations)
    scanned = Scanner.new(@read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

    @locales.each do |locale|
      yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      yaml = nil unless yaml.as_h?

      yaml_tree = if yaml.nil?
                    Tree.new(Node.new(locale, locale))
                  else
                    Tree.from_yaml(yaml)
                  end

      scanned_tree = Tree.from_scanned_results(scanned, locale)
      missing_keys = scanned_tree.missing_keys(yaml_tree, locale, @config.write(key).ignore_missing || [] of String)

      missing_keys.each do |key|
        yaml_tree.add_child_by_key(key)
      end

      YAML.dump(yaml_tree.to_h, File.open("#{@write_directory}/#{locale}.yml", "w"))
    end
  end

  def remove_unused_translations(key, unused_translations)
    scanned = Scanner.new(@read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

    @locales.each do |locale|
      yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      yaml = nil unless yaml.as_h?

      yaml_tree = if yaml.nil?
                    Tree.new(Node.new(locale, locale))
                  else
                    Tree.from_yaml(yaml)
                  end

      scanned_tree = Tree.from_scanned_results(scanned, locale)
      unused_keys = scanned_tree.unused_keys(yaml_tree, locale, @config.write(key).ignore_unused || [] of String)

      unused_keys.each do |key|
        yaml_tree.remove_child_by_key(key)
      end

      if yaml_tree.root.children.empty?
        YAML.dump(nil, File.open("#{@write_directory}/#{locale}.yml", "w"))
      else
        YAML.dump(yaml_tree.to_h, File.open("#{@write_directory}/#{locale}.yml", "w"))
      end
    end
  end

  def normalize_translations(key)
    @locales.each do |locale|
      dir_name = "#{@write_directory}/#{locale}.yml"
      yaml = YAML.parse(File.read(dir_name))
      yaml_tree = Tree.from_yaml(yaml)
      normalized_yaml = yaml_tree.to_h

      YAML.dump(normalized_yaml, File.open(dir_name, "w"))
    end
  end

  private def render_table(keys_hash : Hash(String, Array(String)), title : String, config_locales : Array(String))
    table = TerminalTable.new
    table.headings = ["Locale", "Key"]

    # ALL
    keys_in_all = [] of String
    if @locales == config_locales
      keys_hash[keys_hash.keys.first].each do |key|
        if keys_hash.values.all? { |value| value.includes?(key)}
          keys_in_all << key
          table << ["all".colorize(:blue).to_s, key.colorize(:green).to_s]
        end
      end
    end

    # ONLY IN SOME
    keys_hash.each do |locale, keys|
      new_keys = keys - keys_in_all
      unless new_keys.empty?
        new_keys.each do |key|
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
    #     ignore_missing:
    #     ignore_unused:
    END
  end
end
