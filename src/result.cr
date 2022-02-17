class Result
  def initialize(path : String, position : UInt32, line : String, line_number : UInt32, raw_key : String)
    @path = path
    @position = position
    @line = line
    @line_number = line_number
    @raw_key = raw_key
  end

  def to_s
    "#{@path}:#{@line_number}:#{@position}:#{@raw_key}"
  end
end
