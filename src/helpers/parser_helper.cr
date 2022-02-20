
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
        @yaml_forest[locale] = yaml_tree
        # Note: Nothing that uses missing currently uses the scanned_forsest so
        # we don't add to it here
        scanned_tree = Tree.from_scanned_results(scanned, locale)

        missing_keys_hash[locale] = scanned_tree.missing_keys(yaml_tree, locale, @config.write(key).ignore_missing || [] of String)
      end
    end

    missing_keys_hash
  end

  def unused_translations(key)
    unused_keys_hash = {} of String => Array(String)
    scanned = Scanner.new(@read_directory, @config.read(key).file_types, @config.read(key).exclude).scan

    @locales.each do |locale|
      yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      yaml = nil unless yaml.as_h?

      if yaml.nil?
        unused_keys_hash[locale] = [] of String
      else
        yaml_tree = Tree.from_yaml(yaml)
        @yaml_forest[locale] = yaml_tree
        scanned_tree = Tree.from_scanned_results(scanned, locale.as(String))
        @scanned_forest[locale] = scanned_tree

        unused_keys_hash[locale] = scanned_tree.unused_keys(yaml_tree, locale, @config.write(key).ignore_unused || [] of String)
      end
    end

    unused_keys_hash
  end

  # TODO: I didn't realize this when I wrote it, but this just doesn't use the missing_translations hash that it
  # gets passed and does the work to get the missing keys again, which is a waste of CPU time, since we don't need t o
  # find the missing keys, just read the YAML and jam in the new keys.
  def add_missing_translations(key, missing_translations)
    @locales.each do |locale|
      yaml_tree = if @yaml_forest.has_key?(locale)
                    @yaml_forest[locale]
                  else
                    Tree.new(Node.new(locale, locale))
                  end

      missing_keys = missing_translations[locale]

      missing_keys.each do |key|
        yaml_tree.add_child_by_key(key)
      end

      YAML.dump(yaml_tree.to_h, File.open("#{@write_directory}/#{locale}.yml", "w"))
    end
  end

  # TODO: I didn't realize this when I wrote it, but this just doesn't use the unused_translations hash that it
  # gets passed and does the work to get the unused keys again, which is a waste of CPU time, since we don't need t o
  # find the unused keys, just read the YAML and jam in the new keys.
  def remove_unused_translations(key, unused_translations)
    @locales.each do |locale|
      yaml_tree = if @yaml_forest.has_key?(locale)
                    @yaml_forest[locale]
                  else
                    Tree.new(Node.new(locale, locale))
                  end

      scanned_tree = @scanned_forest[locale]
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

  def translate_missing_translations(key, missing_translations, from : String)
    raise "Could not parse YAML file #{from}.yml, as it is empty!" unless @yaml_forest.has_key?(from)

    from_yaml_tree = @yaml_forest[from]
    @locales.reject! { |locale| locale == from }.each do |locale|
      to_yaml = YAML.parse(File.read("#{@write_directory}/#{locale}.yml"))
      to_yaml = nil unless to_yaml.as_h?
      to_yaml_tree = if @yaml_forest.has_key?(locale)
                       @yaml_forest[locale]
                     else
                       Tree.new(Node.new(locale, locale))
                     end

      missing_keys = missing_translations[locale]
      things_to_translate = missing_keys.map do |key|
        value = from_yaml_tree.find_child("#{from}.#{key}").value
        value.as_s
      end.compact
      translated_things = @translator.translate(things_to_translate, from, locale)
      missing_keys.each_with_index do |key, index|
        to_yaml_tree.add_child_by_key(key, translated_things[index])
      end

      YAML.dump(to_yaml_tree.to_h, File.open("#{@write_directory}/#{locale}.yml", "w"))
    end
  end

  def normalize_translations(key)
    @locales.each do |locale|
      raise "Could not parse YAML file #{locale}.yml, as it is empty!" unless @yaml_forest.has_key?(locale)

      yaml_tree = @yaml_forest[locale]
      normalized_yaml = yaml_tree.to_h

      YAML.dump(normalized_yaml, File.open("#{@write_directory}/#{locale}.yml", "w"))
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
