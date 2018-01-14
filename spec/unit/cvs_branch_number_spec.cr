require "../spec_helper"

describe "CvsBranchNumber" do
  it "basic" do
    BranchNumber.new("1.1").to_a.should eq([1,1])
    BranchNumber.new("1234.1234").to_a.should eq([1234,1234])
    BranchNumber.new("1.2.3.4").to_a.should eq([1,2,3,4])
  end

  it "simple_inherits_from" do
    b = BranchNumber.new("1.3")

    b.inherits_from?(BranchNumber.new("1.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3")).should be_truthy

    b.inherits_from?(BranchNumber.new("1.4")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.1.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.2.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.2.1")).should be_falsey
  end

  it "complex_inherits_from" do
    b = BranchNumber.new("1.3.6.3.2.3")

    b.inherits_from?(BranchNumber.new("1.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.3")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.3.2.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.3.2.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.3.6.3.2.3")).should be_truthy

    b.inherits_from?(BranchNumber.new("1.4")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.1.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.2.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.4.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.6.1.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.6.4")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.6.3.4.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.6.3.2.2.2.1")).should be_falsey
    b.inherits_from?(BranchNumber.new("1.3.6.3.2.4")).should be_falsey
  end

  it "primary_revision_number_change" do
    b = BranchNumber.new("2.3")

    b.inherits_from?(BranchNumber.new("2.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("2.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.9999")).should be_truthy

    b.inherits_from?(BranchNumber.new("2.4")).should be_falsey
    b.inherits_from?(BranchNumber.new("3.1")).should be_falsey
  end

  it "complex_primary_revision_number_change" do
    b = BranchNumber.new("2.3.2.1")

    b.inherits_from?(BranchNumber.new("2.3")).should be_truthy
    b.inherits_from?(BranchNumber.new("2.2")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.1")).should be_truthy
    b.inherits_from?(BranchNumber.new("1.9999")).should be_truthy

    b.inherits_from?(BranchNumber.new("3.1")).should be_falsey
  end


  it "simple_on_same_line" do
    b = BranchNumber.new("1.3")

    b.on_same_line?(BranchNumber.new("1.2")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.1")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.4")).should be_truthy

    b.on_same_line?(BranchNumber.new("1.1.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.2.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.2.1")).should be_falsey
  end

  it "complex_on_same_line" do
    b = BranchNumber.new("1.3.6.3.2.3")

    b.on_same_line?(BranchNumber.new("1.1")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.2")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.1")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.2")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.1")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.2")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.3")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.4")).should be_truthy
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.99")).should be_truthy

    b.on_same_line?(BranchNumber.new("1.4")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.1.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.2.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.4.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.6.1.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.6.4")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.6.3.4.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.2.2.1")).should be_falsey
    b.on_same_line?(BranchNumber.new("1.3.6.3.2.99.2.1")).should be_falsey
  end


  # Crazy CVS inserts a zero before the last piece of a branch number
  it "magic_branch_numbers" do
    BranchNumber.new("1.1.2.1").on_same_line?(BranchNumber.new("1.1.0.2")).should be_truthy
    BranchNumber.new("1.1.2.1.2.1").on_same_line?(BranchNumber.new("1.1.0.2")).should be_truthy

    BranchNumber.new("1.1.0.2").on_same_line?(BranchNumber.new("1.1")).should be_truthy
    BranchNumber.new("1.1.0.2").on_same_line?(BranchNumber.new("1.2")).should be_falsey
    BranchNumber.new("1.1.0.2").on_same_line?(BranchNumber.new("1.1.2.1")).should be_truthy

    BranchNumber.new("1.1.0.4").on_same_line?(BranchNumber.new("1.1")).should be_truthy
    BranchNumber.new("1.1.0.4").on_same_line?(BranchNumber.new("1.1.2.1")).should be_falsey
    BranchNumber.new("1.1.0.4").on_same_line?(BranchNumber.new("1.1.0.2")).should be_falsey
    BranchNumber.new("1.1.0.4").on_same_line?(BranchNumber.new("1.1.4.1")).should be_truthy
    BranchNumber.new("1.1.0.4").on_same_line?(BranchNumber.new("1.1.0.6")).should be_falsey
  end
end
