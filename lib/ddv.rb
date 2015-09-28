#!/usr/bin/env ruby

require "ddv/version"
require 'fileutils'
require 'optparse'

module Ddv
  def self.parse_command_line_options
    options = {}
    OptionParser.new("USAGE: #{File.basename($0)} [OPTION]... [DIRECTORY]
List recursively all files/directories in a directory.") do |opt|
      opt.on("-m [max_number_of_files_to_list]",
             "--max-files-to-list [=max_number_of_files_to_list]",
             "Specify the maximum number of file names to be listed.") do |n|
        options[:max_detailed_files_num] = n.to_i
      end

      opt.on("-i", "--ignore_file_types",
             "Ignore file types when counting files in a directory.") do |i|
        options[:ignore_file_type] = i
      end

      opt.parse!
    end
    options
  end

  private_class_method :parse_command_line_options

  def self.execute
    options = parse_command_line_options
    printer = NodePrinter.new(options[:max_detailed_files_num],
                              options[:ignore_file_type])
    directory = ARGV[0] || "."
    DirVisitor.new(printer).tree(directory)
  end

  class DirVisitor
    def initialize(output=NodePrinter.new)
      @output = output
    end

    def tree(parent_dir, level=0)
      @output.output_dir(File.basename(parent_dir), level)
      nodes = Dir.entries(parent_dir) - [".", ".."]
      dirs, files = nodes.partition {|n| dir?(parent_dir, n) }.map(&:sort)
      @output.output_files(files, level)
      dirs.each do |dir|
        tree(File.join(parent_dir, dir), level + 1)
      end
    end
    
    def dir?(parent_dir, node)
      File.directory?(File.join(parent_dir, node))
    end
  end

  class NodePrinter
    def initialize(max_detailed_files_num=nil, ignore_file_type=false)
      @max_detailed_files_num = max_detailed_files_num
      @ignore_file_type = ignore_file_type
    end

    def output_files(files, level)
      if @max_detailed_files_num and files.size > @max_detailed_files_num
        output_files_summary(files)
      else
        puts
        files.each {|file| output_file(file, level) }
      end
    end
    
    def output_dir(dir, level)
      print "  " * level
      print "[#{dir}]"
    end

    def output_files_summary(files)
      if @ignore_file_type
        puts " => #{files.size} files"
      else
        puts " => #{report_file_types(files)}"
      end
    end
    
    private

    def output_file(file, level)
      print "  " * level + "  * "
      puts file
    end

    def report_file_types(files)
      format_counter(count_by_file_type(files))
    end

    def count_by_file_type(files)
      counter = Hash.new(0)
      files.each do |file|
        m = /\.([^.]+)\Z/.match(file) # extract file extention
        ext = m ? m[1] : "others"
        counter[ext] += 1
      end
      counter
    end

    def format_counter(counter)
      counter.map do |entry|
        type, count = entry
        plural = count == 1 ? "" : "s"
        format("%s: %d file%s", type, count, plural)
      end.join(" / ")
    end
  end
end

if $0 == __FILE__
  Ddv.execute
end
