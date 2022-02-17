
describe Scanner do
  it "locates files" do
    Scanner.new("spec/scanner").files.size.should be > 0
  end

  it "reads translations to tree" do
    result = %w[edit.the.world destroy.all.humans destroy.the.world destroy.nuclear]
    result_part_two = %w[edit.the.paper destroy.all.gamers destroy.the.freaking.factory mission]
    Scanner.new("spec/scanner").scan.should eq(Set(String).new(result.concat(result_part_two)))
  end
end
