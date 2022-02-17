require "./spec_helper"

describe Tree do
  # TODO: Write tests

  it "correctly reads from yaml" do
    tree = Tree.from_yaml(yaml)

    tree.should be_a(Tree)
    tree.root.should be_a(Node)
    tree.should eq(mock_tree)
  end

  describe "correctly finds" do
    it "first child" do
      mock_tree.find_child("en.schools").should eq(mock_tree.root.children.first)
    end

    it "nested child" do
      child = mock_tree.root.children.first.children.first
      mock_tree.find_child("en.schools.name").should eq(child)
    end

    it "super nested child" do
      child = mock_tree.root.children.first.children[2].children.last.children.first
      mock_tree.find_child("en.schools.events.dashboard.memberships").should eq(child)
    end
  end

  it "gets all leaves" do
    mock_tree.root.all_leaves.should eq(mock_all_leaves)
  end

  it "gets the missing diff correctly" do
    tree = Tree.from_yaml(yaml)
    tree_2 = Tree.from_yaml(yaml_2)

    missing = tree.missing(tree_2).map { |node| node.full_name }

    missing.should eq(%w[en.schools.name en.schools.events.all en.gyms.hell])
  end

  it "gets the unused diff correctly" do
    tree = Tree.from_yaml(yaml)
    tree_2 = Tree.from_yaml(yaml_2)

    unused = tree_2.unused(tree).map { |node| node.full_name }

    unused.should eq(%w[en.schools.name en.schools.events.all en.gyms.hell])
  end

  it "correctly reads from scanned results" do
    tree = Tree.from_scanned_results(mock_scanned_results, "en")

    tree.should be_a(Tree)
    tree.root.should be_a(Node)
    tree.should eq(mock_tree)
  end
end
