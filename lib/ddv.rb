#!/usr/bin/env ruby

require "ddv/version"
require 'fileutils'

module Ddv
  class DirVisitor
    def initialize(output=NodePrinter.new)
      @output = output
    end

    def tree(parent_dir, max_detailed_files_num=nil, level=0)
      @output.output_dir(File.basename(parent_dir), level)
      nodes = Dir.entries(parent_dir) - [".", ".."]
      dirs = nodes.select {|n| dir?(parent_dir, n) }.sort
      files = (nodes - dirs).sort
      @output.output_files(files, max_detailed_files_num, level)
      dirs.each do |dir|
        tree(File.join(parent_dir, dir), max_detailed_files_num, level + 1)
      end
    end
    
    def dir?(parent_dir, node)
      File.directory?(File.join(parent_dir, node))
    end
  end

  class NodePrinter
    def output_files(files, max_detailed_files_num, level)
      if max_detailed_files_num and files.size > max_detailed_files_num
        output_files_summary(files)
      else
        puts
        files.each {|file| output_file(file, level) }
      end
    end
    
    def output_files_summary(files)
      puts " => #{files.size} files"
    end
    
    def output_dir(dir, level)
      print "  " * level
      print "[#{dir}]"
    end
    
    def output_file(file, level)
      print "  " * level + "  * "
      puts file
    end
  end
end

if $0 == __FILE__
  Ddv::DirVisitor.new.tree(ARGV[0])
end
