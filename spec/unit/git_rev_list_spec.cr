require "../spec_helper"

# Repository git_walk has the following structure:
#
#      G -> H -> I -> J -> development
#     /      \    \
#    A -> B -> C -> D -> master
#
describe "GitRevList" do

  it "rev_list" do
    with_git_repository("git_walk") do |git|
      # Full history to a commit
      rev_list_helper(git, nil, :A).should eq([:A])
      rev_list_helper(git, nil, :B).should eq([:A, :B])
      rev_list_helper(git, nil, :C).should eq([:A, :B, :G, :H, :C])
      rev_list_helper(git, nil, :D).should eq([:A, :B, :G, :H, :C, :I, :D])
      rev_list_helper(git, nil, :G).should eq([:A, :G])
      rev_list_helper(git, nil, :H).should eq([:A, :G, :H])
      rev_list_helper(git, nil, :I).should eq([:A, :G, :H, :I])
      rev_list_helper(git, nil, :J).should eq([:A, :G, :H, :I, :J])

      # Limited history from one commit to another
      rev_list_helper(git, :A, :A).should eq(Array(Nil).new)
      rev_list_helper(git, :A, :B).should eq([:B])
      rev_list_helper(git, :A, :C).should eq([:B, :G, :H, :C])
      rev_list_helper(git, :A, :D).should eq([:B, :G, :H, :C, :I, :D])
      rev_list_helper(git, :B, :D).should eq([:G, :H, :C, :I, :D])
      rev_list_helper(git, :C, :D).should eq([:I, :D])
      rev_list_helper(git, :G, :J).should eq([:H, :I, :J])
    end
  end

  it "trunk_only_rev_list" do
    with_git_repository("git_walk") do |git|
      # Full history to a commit
      rev_list_trunk(git, nil, :A).should eq([:A])
      rev_list_trunk(git, nil, :B).should eq([:A, :B])
      rev_list_trunk(git, nil, :C).should eq([:A, :B, :C])
      rev_list_trunk(git, nil, :D).should eq([:A, :B, :C, :D])

      # Limited history from one commit to another
      rev_list_trunk(git, :A, :A).should eq(Array(Nil).new)
      rev_list_trunk(git, :A, :B).should eq([:B])
      rev_list_trunk(git, :A, :C).should eq([:B, :C])
      rev_list_trunk(git, :A, :D).should eq([:B, :C, :D])
      rev_list_trunk(git, :B, :D).should eq([:C, :D])
      rev_list_trunk(git, :C, :D).should eq([:D])
    end
  end
end

def rev_list_helper(git, from, to)
  to_labels(git.commit_tokens(after: from_label(from), up_to: from_label(to)))
end

def rev_list_trunk(git, from, to)
  to_labels(git.commit_tokens(after: from_label(from), up_to: from_label(to), trunk_only: true))
end

def commit_labels
  { "886b62459ef1ffd01a908979d4d56776e0c5ecb2" => :A,
    "db77c232f01f7a649dd3a2216199a29cf98389b7" => :B,
    "f264fb40c340a415b305ac1f0b8f12502aa2788f" => :C,
    "57fedf267adc31b1403f700cc568fe4ca7975a6b" => :D,
    "97b80cb9743948cf302b6e21571ff40721a04c8d" => :G,
    "b8291f0e89567de3f691afc9b87a5f1908a6f3ea" => :H,
    "d067161caae2eeedbd74976aeff5c4d8f1ccc946" => :I,
    "b49aeaec003cf8afb18152cd9e292816776eecd6" => :J
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
