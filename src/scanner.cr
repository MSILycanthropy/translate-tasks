require "./helpers/scanner_helper"

# TODO: Implement some AST fallback stuff for string interps
class Scanner
  include ScannerHelper

  CALL_RE = /(?<=^|[^\w'\-.]|[^\w'\-]I18n\.|I18n\.)t(?:!|ranslate!?)?[( ][\r\n\t ]*(:?".+?"|:?'.+?'|:\w+)/

  def initialize(directory : String, file_types : Array(String), exclude_directory : String?)
    @directory = directory
    @file_types = file_types
    @exclude_directory = exclude_directory
  end

  def files
    Dir.glob(full_glob_pattern).map do |file|
      file
    end
  end

  def scan : Set(String)
    matches = Set(String).new

    files.each do |file|
      content = File.read(file)
      matches.concat(content.scan(CALL_RE).map { |match| strip_key(match) })
    end

    matches.reject { |key| key.includes?("\#{") }.to_set
  end

  private def full_glob_pattern
    if @exclude_directory
      File.join(@directory, "{!(#{@exclude_directory.as(String)}), **}/*{#{@file_types.join(',')}}")
    else
      puts File.join(@directory, "**/*{#{@file_types.join(',')}}")
      File.join(@directory, "**/*{#{@file_types.join(',')}}")
    end
  end
end
