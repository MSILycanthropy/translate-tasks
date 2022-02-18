struct Config
  property path, keys, settings

  ALL_BASE_SETTINGS = %w[base_locale locales read write]
  ALL_READ_SETTINGS = %w[directory file_types exclude]
  ALL_WRITE_SETTINGS = %w[directory file_name single_file ignore_missing ignore_unused]

  @path : String
  @keys : Array(String)
  @settings : Hash(YAML::Any, YAML::Any)
  def initialize(path)
    @path = path
    if !File.exists?(@path)
      @keys = [] of String
      @settings = {} of YAML::Any => YAML::Any
      return
    end

    yaml = YAML.parse(File.read(@path))
    @keys = yaml["settings_keys"].as_a.map { |k| k.to_s }
    @settings = yaml.as_h.select! { |k, _| k != "settings_keys" }

    deny_invalid_keys!
  end

  def get(key, setting_key)
    @settings[key].as_h[setting_key]
  end

  def base_locale(key)
    get(key, "base_locale")
  end

  def locales(key)
    get(key, "locales").as_a.map { |locale| locale.as_s }
  end

  def read(key)
    ReadSettings.new(get(key, "read").as_h)
  end

  def write(key)
    WriteSettings.new(get(key, "write").as_h)
  end

  private def deny_invalid_keys!
    @keys.each do |key|
      base = @settings[key].as_h
      write = get(key, "write").as_h
      read = get(key, "read").as_h

      unless (base.keys - ALL_BASE_SETTINGS).empty?
        raise "Invalid base settings for #{key}: #{base.keys - ALL_BASE_SETTINGS}"
      end

      unless (write.keys - ALL_WRITE_SETTINGS).empty?
        raise "Invalid write settings for #{key}: #{write.keys - ALL_WRITE_SETTINGS}"
      end

      unless (read.keys - ALL_READ_SETTINGS).empty?
        raise "Invalid read settings for #{key}: #{read.keys - ALL_READ_SETTINGS}"
      end
    end
  end
end
