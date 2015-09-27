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
    assert_output(expected_output) { Ddv::DirVisitor.new(Ddv::NodePrinter.new(1)).tree("test/data") }
  end

  def test_summarized_2_output
    expected_output = File.read(in_cur_dir("output_data/summarized_2.txt"))
    assert_output(expected_output) { Ddv::DirVisitor.new(Ddv::NodePrinter.new(2)).tree("test/data") }
  end
end

class TestNodePrinter < MiniTest::Unit::TestCase
  def test_output_files_summary
    files = %w(README penguin.txt index.html ostrich.txt penguin.jpg)
    expected_default_result = " => others: 1 file / txt: 2 files / html: 1 file / jpg: 1 file\n"
    expected_file_type_ignored_result = " => 5 files\n"
    assert_output(expected_default_result) do
      Ddv::NodePrinter.new(2).output_files_summary(files)
    end
    assert_output(expected_file_type_ignored_result) do
      Ddv::NodePrinter.new(2, true).output_files_summary(files)
    end
  end
end
