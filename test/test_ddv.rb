require 'minitest_helper'

class TestDdv < MiniTest::Unit::TestCase

  def in_cur_dir(filename)
    @cur_dir ||= File.dirname(File.expand_path(__FILE__))
    File.join(@cur_dir, filename)
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ddv::VERSION
  end

  def test_default_output
    expected_output = File.read(in_cur_dir("output_data/default.txt"))
    assert_output(expected_output) { Ddv::DirVisitor.new.tree("test/data") }
  end

  def test_summarized_1_output
    expected_output = File.read(in_cur_dir("output_data/summarized_1.txt"))
    assert_output(expected_output) { Ddv::DirVisitor.new.tree("test/data", 1) }
  end

  def test_summarized_2_output
    expected_output = File.read(in_cur_dir("output_data/summarized_2.txt"))
    assert_output(expected_output) { Ddv::DirVisitor.new.tree("test/data", 2) }
  end
end
