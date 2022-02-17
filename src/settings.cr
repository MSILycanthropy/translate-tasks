
struct ReadSettings
  property directory, exclude, file_types

  @directory : String
  @exclude : String | Nil
  @file_types : Array(String)

  def initialize(settings)
    @directory = settings["directory"].as(String)
    @file_types = settings["file_types"].as(Array(String))
    @exclude = settings["exclude"].as(String | Nil) if settings.has_key?("exclude")
  end
end

struct WriteSettings
  property directory, single_file, ignore_missing, ignore_unused, file_directory

  @directory : String
  @single_file : Bool | Nil
  @ignore_missing : Array(String) | Nil
  @ignore_unused : Array(String) | Nil

  def initialize(settings : Hash(String, (Array(String) | Bool | Hash(String, Array(String) | Bool | String) | String)))
    @directory = settings["directory"].as(String)
    @single_file = settings["single_file"].as(Bool | Nil) if settings.has_key?("single_file")
    @ignore_missing = settings["ignore_missing"].as(Array(String) | Nil) if settings.has_key?("ignore_missing")
    @ignore_unused = settings["ignore_unused"].as(Array(String) | Nil) if settings.has_key?("ignore_unused")
  end
end
