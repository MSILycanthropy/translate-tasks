# Loose wrapper around node, to help with some root stuff
# since the actual root of the tree doesn't really
# do much other than identify the tree as the locale
struct Tree
  property root

  def initialize(root : Node)
    @root = root
  end

  def find_child(name_chain : String)
    @root.find_child(name_chain)
  end

  def missing(other : Tree)
    @root.missing(other.root)
  end

  def unused(other : Tree)
    other.root.missing(@root)
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
end
