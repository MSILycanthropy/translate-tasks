# Loose wrapper around node, to help with some root stuff
# since the actual root of the tree doesn't really
# do much other than identify the tree as the locale
class Tree
  property root

  def initialize(root : Node)
    @root = root
  end

  def find_child(name_chain : String)
    @root.find_child!(name_chain)
  end

  def missing(other : Tree)
    @root.missing(other.root)
  end

  def missing_keys(other : Tree, locale : String, ignored : Array(String)) : Array(String)
    missing_keys = missing(other).map { |missing| missing.full_name.gsub("#{locale}.", "") }

    (missing_keys - ignored_keys(ignored, missing_keys)).reject! { |key| key.includes?("\#{") }
  end

  def unused_keys(other : Tree, locale : String, ignored : Array(String)) : Array(String)
    unused_keys = unused(other).map { |missing| missing.full_name.gsub("#{locale}.", "") }

    (unused_keys - ignored_keys(ignored, unused_keys)).reject! { |key| key.includes?("\#{") }
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

  def unused(other : Tree)
    other.root.missing(@root)
  end

  def to_hash : Hash(YAML::Any, YAML::Any)
    { YAML::Any.new(@root.name) => YAML::Any.new(@root.to_h) }
  end

  def to_h : Hash(YAML::Any, YAML::Any)
    to_hash
  end

  def add_children_by_keys(keys : Array(String))
    @root.add_children_by_keys(keys)
  end

  def remove_child_by_key(key : String)
    @root.remove_child_by_key(key)
  end

  def self.from_yaml(yaml : YAML::Any)
    root = Node.new(yaml.as_h.keys[0].as_s, yaml.as_h.keys[0].as_s)
    root.children_from_yaml(yaml.as_h.values[0])

    Tree.new(root)
  end

  def self.from_scanned_results(results : Set, locale : String)
    root = Node.new(locale, locale)
    root.children_from_scanned_results(results)
    Tree.new(root)
  end

  def to_s(io)
    io << to_h
  end
end
