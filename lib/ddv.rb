#!/usr/bin/env ruby

require 'fileutils'

def tree(parent_dir, max_detailed_files_num=nil, level=0)
  print_dir(File.basename(parent_dir), level)
  nodes = Dir.entries(parent_dir) - [".", ".."]
  dirs = nodes.select {|n| dir?(parent_dir, n) }.sort {|x, y| x <=> y }
  files = (nodes - dirs).sort {|x, y| x <=> y }
  if max_detailed_files_num and files.size > max_detailed_files_num
    print_files_summary(files)
  else
    puts
    files.each {|file| print_file(file, level) }
  end
  dirs.each do |dir|
    tree(File.join(parent_dir, dir), max_detailed_files_num, level + 1)
  end
end

def dir?(parent_dir, node)
  File.directory?(File.join(parent_dir, node))
end

def print_files_summary(files)
  puts " => #{files.size} files"
end

def print_dir(dir, level)
  print "  " * level
  print "[#{dir}]"
end

def print_file(file, level)
  print "  " * level + "  *"
  puts file
end

tree("test")

