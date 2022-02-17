require "spec"
require "../src/translate-tasks"


def yaml
  text = <<-END
  ---
  en:
    schools:
      name: Name
      title: Title
      events:
        all: all
        dashboard:
          memberships: memberships
      end: end
    gyms:
      hell: hell
  END

  YAML.parse(text)
end


def yaml_2
  text = <<-END
  ---
  en:
    schools:
      end: end
      events:
        dashboard:
          memberships: memberships
      title: Title
  END

  YAML.parse(text)
end

def mock_tree
  root = Node.new("en", "en")
  schools = Node.new("schools", "en.schools")
  name = Node.new("name", "en.schools.name")
  title = Node.new("title", "en.schools.title")
  events = Node.new("events", "en.schools.events")
  all = Node.new("all", "en.schools.events.all")
  dashboard = Node.new("dashboard", "en.schools.events.dashboard")
  memberships = Node.new("memberships", "en.schools.events.dashboard.memberships")
  endNode = Node.new("end", "en.schools.end")
  gyms = Node.new("gyms", "en.gyms")
  hell = Node.new("hell", "en.gyms.hell")

  gyms.add_child(hell)

  dashboard.add_child(memberships)

  events.add_child(all)
  events.add_child(dashboard)

  schools.add_child(name)
  schools.add_child(title)
  schools.add_child(events)
  schools.add_child(endNode)

  root.add_child(schools)
  root.add_child(gyms)

  tree = Tree.new(root)
end

def mock_all_leaves
  schools = Node.new("schools", "en.schools")
  name = Node.new("name", "en.schools.name")
  title = Node.new("title", "en.schools.title")
  events = Node.new("events", "en.schools.events")
  all = Node.new("all", "en.schools.events.all")
  dashboard = Node.new("dashboard", "en.schools.events.dashboard")
  memberships = Node.new("memberships", "en.schools.events.dashboard.memberships")
  endNode = Node.new("end", "en.schools.end")
  gyms = Node.new("gyms", "en.gyms")
  hell = Node.new("hell", "en.gyms.hell")

  [name, title, all, memberships, endNode, hell]
end

def mock_scanned_results
  Set(String).new(mock_tree.root.all_leaves.map { |node| node.full_name.gsub("en.", "") })
end
