struct Node
  property name, full_name, children, value

  def initialize(name : String, full_name : String, children : Array(Node) = [] of Node, value : YAML::Any = YAML::Any.new(""))
    @name = name
    @full_name = full_name
    @children = children
    @value = value
  end

  def ==(other : Node)
    return false unless @children.size == other.children.size
    equal = true
    equal &&= @name == other.name
    equal &&= @full_name == other.full_name
    @children.each do |child|
      other_child = other.find_child(child.full_name)
      equal &&= child == other_child
    end

    equal
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
        if value.as_s? || value.as_a?
          _children << Node.new(key.as_s, "#{full_name}.#{key.as_s}", value: value)
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

  def to_hash : Hash(YAML::Any, YAML::Any)
    hash = {} of YAML::Any => YAML::Any
    @children.each do |child|
      if child.value.as_s? != "" || child.value.as_a?
        hash[YAML::Any.new(child.name)] = child.value
      else
        hash[YAML::Any.new(child.name)] = YAML::Any.new(child.to_hash)
      end
    end

    sorted_hash = {} of YAML::Any => YAML::Any
    hash.keys.map{ |k| k.as_s }.sort.each do |key|
      sorted_hash[YAML::Any.new(key)] = hash[YAML::Any.new(key)]
    end

    sorted_hash
  end

  def to_h
    to_hash
  end

  def add_child_by_key(key : String)
    node_names = key.split('.')
    current_node = self

    node_names.each_with_index do |node_name, index|
      if current_node.find_first_child?(node_name)
        current_node = current_node.find_first_child!(node_name)
      else
        remaining_names = node_names[index..]
        nodes = remaining_names.map do |name|
          if name == remaining_names.last
            Node.new(name, "#{current_node.full_name}.#{name}",
                     value: YAML::Any.new(remaining_names.last.gsub("_", " ").capitalize))
          else
            Node.new(name, "#{current_node.full_name}.#{name}")
          end
        end

        nodes.reduce do |node, next_node|
          node.add_child(next_node)
          next_node
        end

        current_node.add_child(nodes.first)
      end
    end
  end

  def remove_child_by_key(key : String)
    name = "#{full_name}.#{key}"
    child = find_child(name)

    if child
      parent_name = child.full_name.split('.')[0..-2].join('.')
      parent = find_child(parent_name)
      parent.children.delete(child) if parent

      if parent && parent.value.as_s == "" && parent.children.empty?
        remove_child_by_key(parent_name.split('.')[1..].join('.'))
      end
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

  def find_first_child? (name : String)
    find_first_child(name) != nil
  end

  def find_first_child!(name : String)
    find_first_child(name) || raise "No such child: #{name}"
  end

  def find_first_child(name : String)
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
