struct Config
  property path, keys, settings

  ALL_BASE_SETTINGS = %w[base_locale locales read write]
  ALL_READ_SETTINGS = %w[directory file_types exclude]
  ALL_WRITE_SETTINGS = %w[directory file_name single_file ignore_missing ignore_unused]

  @path : String
  @keys : Array(String)
  @settings : Hash(String, Hash(String, Array(String) | Bool | Hash(String, Array(String) | Bool | String) | String))
  def initialize(path)
    @path = path
    if !File.exists?(@path)
      @keys = [] of String
      @settings = {} of String => Hash(String, Array(String) | Bool | Hash(String, Array(String) | Bool | String) | String)
      return
    end

    yaml = YAML.parse(File.read(@path))
    @keys = yaml["settings_keys"].as_a.map { |k| k.to_s }

    @settings = @keys.zip(key_hashes(yaml)).to_h
    deny_invalid_keys!
  end

  def get(key, setting_key)
    @settings[key][setting_key]
  end

  def base_locale(key)
    get(key, "base_locale")
  end

  def locales(key)
    get(key, "locales")
  end

  def read(key)
    ReadSettings.new(get(key, "read").as(Hash))
  end

  def write(key)
    WriteSettings.new(get(key, "write").as(Hash))
  end

  private def deny_invalid_keys!
    @keys.each do |key|
      base = @settings[key]
      write = get(key, "write").as(Hash)
      read = get(key, "read").as(Hash)

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

  private def key_hashes(yaml)
    @keys.map do |key|
      hash = {} of String => Bool | String | Array(String) | Hash(String, String | Array(String) | Bool)
      yaml[key].as_h.each do |k, v|
        k = k.as_s
        if v.as_s?
          hash[k] = v.as_s
        elsif v.as_bool?
          hash[k] = v.as_bool
        elsif v.as_a?
          hash[k] = v.as_a.map { |v| v.as_s }
        elsif v.as_h?
          inner_hash = {} of String => String | Array(String) | Bool
          v.as_h.each do |_k, _v|
            _k = _k.as_s
            if _v.as_s?
              inner_hash[_k] = _v.as_s
            elsif _v.as_a?
              inner_hash[_k] = _v.as_a.map { |v| v.as_s }
            elsif _v.as_bool?
              inner_hash[_k] = _v.as_bool
            end
          end
          hash[k] = inner_hash
        end
      end

      hash
    end
  end
end
