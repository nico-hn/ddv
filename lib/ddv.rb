#!/usr/bin/env ruby

require 'fileutils'

def tree(parent_dir, level=0)
  print_dir(File.basename(parent_dir), level)
  Dir.entries(parent_dir).each do |node|
    next if [".", ".."].include? node
    if dir?(parent_dir, node)
      tree(File.join(parent_dir, node), level + 1)
    else
      print_file(node, level)
    end
  end
end

def dir?(parent_dir, node)
  File.directory?(File.join(parent_dir, node))
end

def print_dir(dir, level)
  print "  " * level
  puts "[#{dir}]"
end

def print_file(file, level)
  print "  " * level + "  *"
  puts file
end

tree("test")

