#!/usr/bin/env ruby

require "ddv/version"
require 'fileutils'

module Ddv
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
    def initialize(max_detailed_files_num=nil)
      @max_detailed_files_num = max_detailed_files_num
    end

    def output_files(files, level)
      if @max_detailed_files_num and files.size > @max_detailed_files_num
        output_files_summary(files)
      else
        puts
        files.each {|file| output_file(file, level) }
      end
    end
    
    def output_files_summary(files)
      puts " => #{report_file_types(files)}"
    end
    
    def output_dir(dir, level)
      print "  " * level
      print "[#{dir}]"
    end
    
    def output_file(file, level)
      print "  " * level + "  * "
      puts file
    end

    def report_file_types(files)
      format_counter(count_by_file_type(files))
    end

    private

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
  Ddv::DirVisitor.new.tree(ARGV[0])
end
