module ScannerHelper
  def strip_key(match)
    match[0].scan(/:?".+?"|:?'.+?'|:\w+/).first[0].gsub(/:|"|'/, "")
  end
end
