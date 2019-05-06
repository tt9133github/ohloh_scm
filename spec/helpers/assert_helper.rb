module AssertHelper
  def assert_convert(parser, log, expected)
    result = ''
    parser.parse File.new(log), writer: OhlohScm::XmlWriter.new(result)
    assert_buffers_equal File.read(expected), result
  end

  def assert_buffers_equal(expected, actual)
    return if expected == actual

    expected_lines = expected.split("\n")
    actual_lines = actual.split("\n")
    expected_lines.each_with_index do |line, i|
      assert_equal line, actual_lines[i], "at line #{i} of the reference buffer" if line != actual_lines[i]
    end
  end
end
