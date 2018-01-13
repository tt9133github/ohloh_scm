require "../test_helper"

describe "StringEncoderCommandLine" do
  it "length_of_content_unchanged" do
    file_path = File.expand_path("../../data/sample-content", __FILE__)
    original_content_length = File.size(file_path)
    original_content_lines = File.readlines(file_path).size

    output = %x[cat #{ file_path } \
      | #{ OhlohScm::Adapters::AbstractAdapter.new.string_encoder } ]

    output.length.should eq(original_content_length)
    output.split("\n").length.should eq(original_content_lines)
  end

  it "encoding_invalid_characters" do
    invalid_utf8_word_path =
      File.expand_path("../../data/invalid-utf-word", __FILE__)

    string = %x[cat #{ invalid_utf8_word_path } \
      | #{ OhlohScm::Adapters::AbstractAdapter.new.string_encoder } ]

    string.valid_encoding?.should eq(true)
  end
end
