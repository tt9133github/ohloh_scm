require "../spec_helper"

# Repository hg_walk has the following structure:
#
#      G -> H -> I
#     /      \    \
#    A -> B -> C -> D -> tip
#
describe "HgRevList" do

  it "rev_list" do
    with_hg_repository("hg_walk") do |hg|
      # Full history to a commit
      rev_list_helper(hg, nil, :A).should eq([:A])
      rev_list_helper(hg, nil, :B).should eq([:A, :B])
      rev_list_helper(hg, nil, :C).should eq([:A, :B, :G, :H, :C])
      rev_list_helper(hg, nil, :D).should eq([:A, :B, :G, :H, :C, :I, :D])
      rev_list_helper(hg, nil, :G).should eq([:A, :G])
      rev_list_helper(hg, nil, :H).should eq([:A, :G, :H])
      rev_list_helper(hg, nil, :I).should eq([:A, :G, :H, :I])

      # Limited history from one commit to another
      rev_list_helper(hg, :A, :A).should eq(Array(Nil).new)
      rev_list_helper(hg, :A, :B).should eq([:B])
      rev_list_helper(hg, :A, :C).should eq([:B, :G, :H, :C])
      rev_list_helper(hg, :A, :D).should eq([:B, :G, :H, :C, :I, :D])
      rev_list_helper(hg, :B, :D).should eq([:G, :H, :C, :I, :D])
      rev_list_helper(hg, :C, :D).should eq([:I, :D])
    end
  end
end

def rev_list_helper(hg, from, to)
  to_labels(hg.commit_tokens(after: from_label(from), up_to: from_label(to)))
end

def commit_labels
  { "4bfbf836feeebb236492199fbb0d1474e26f69d9" => :A,
    "23edb79d0d06c8c315d8b9e7456098823335377d" => :B,
    "7e33b9fde56a6e3576753868d08fa143e4e8a9cf" => :C,
    "8daa1aefa228d3ee5f9a0f685d696826e88266fb" => :D,
    "e43cf1bb4b80d8ae70a695ec070ce017fdc529f3" => :G,
    "dca215d8a3e4dd3e472379932f1dd9c909230331" => :H,
    "3a1495175e40b1c983441d6a8e8e627d2bd672b6" => :I
  }
end

def to_label(sha1)
  commit_labels[sha1.to_s]
end

def to_labels(sha1s)
  sha1s.map { |sha1| to_label(sha1) }
end

def from_label(l)
  commit_labels.to_a.find { |_k,v| v.to_s == l.to_s }.try &.first
end
