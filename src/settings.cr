
struct ReadSettings
  property directory, exclude, file_types

  @directory : String
  @exclude : String | Nil
  @file_types : Array(String)

  def initialize(settings :  Hash(YAML::Any, YAML::Any))
    @directory = settings["directory"].as_s
    @file_types = settings["file_types"].as_a.map { |t| t.as_s }
    @exclude = settings["exclude"].as_s if settings.has_key?("exclude")
  end
end

struct WriteSettings
  property directory, single_file, ignore_missing, ignore_unused, file_directory

  @directory : String
  @single_file : Bool | Nil
  @ignore_missing : Array(String) | Nil
  @ignore_unused : Array(String) | Nil

  def initialize(settings :  Hash(YAML::Any, YAML::Any))
    @directory = settings["directory"].as_s
    @single_file = settings["single_file"].as_bool if settings.has_key?("single_file")
    @ignore_missing = settings["ignore_missing"].as_a.map{ |v| v.as_s } if settings.has_key?("ignore_missing")
    @ignore_unused = settings["ignore_unused"].as_a.map{ |v| v.as_s } if settings.has_key?("ignore_unused")
  end
end
