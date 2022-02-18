struct Node
  property name, full_name, children

  def initialize(name : String, full_name : String, children : Array(Node) = [] of Node)
    @name = name
    @full_name = full_name
    @children = children
  end

  def add_child(child : Node)
    @children << child
  end

  def add_children(children : Array(Node))
    @children.concat(children)
  end

  def find_child(full_name : String)
    if @full_name == full_name
      return self
    end

    @children.each do |child|
      result = child.find_child(full_name)
      return result if result
    end
  end

  def find_child?(name_chain : String)
    find_child(name_chain) != nil
  end

  def find_child!(name_chain : String)
    find_child(name_chain) || raise "No such child: #{name_chain}"
  end

  def children_from_yaml(yaml)
    _children = [] of Node

    if yaml.as_h?
      yaml.as_h.each do |key, value|
        if value.as_s?
          _children << Node.new(key.as_s, "#{full_name}.#{key.as_s}")
          next
        else
          child = Node.new(key.as_s, "#{full_name}.#{key.as_s}")
          child.children_from_yaml(value)
          _children << child
        end
      end
    end

    add_children(_children)
  end

  def children_from_scanned_results(results : Set(String))
    results.group_by { |result| result.split('.').first }.each do |key, values|
      child = Node.new(key, "#{full_name}.#{key}")
      new_values = values.map { |value| value.split('.')[1..].join('.') }.reject! { |value| value.empty? }

      if new_values.size == 1 && !new_values.first.includes?('.')
        child.add_child(Node.new(new_values.first, "#{full_name}.#{values.first}"))
      else
        child.children_from_scanned_results(new_values.to_set)
      end

      add_child(child)
    end
  end

  def missing(other : Node)
    missing = [] of Node

    @children.each do |child|
      other_child = other.find_child(child.full_name)

      if other_child
        missing.concat(child.missing(other_child))
      else
        if child.has_children?
          missing.concat(child.all_leaves)
        else
          missing << child
        end
      end
    end

    missing
  end

  def has_children?
    @children.size > 0
  end

  def all_leaves
    nodes = [] of Node

    @children.each do |child|
      if child.has_children?
        nodes.concat(child.all_leaves)
      else
        nodes << child
      end
    end

    nodes
  end

  private def find_first_child(name : String)
    if @name == name
      return self
    end

    if @children
      @children.each do |child|
        result = child.find_first_child(name)
        return result if result
      end
    end
  end
end
