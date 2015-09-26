#!/usr/bin/env ruby

require 'fileutils'

def tree(parent_dir, level=0)
  print_dir(File.basename(parent_dir), level)
  nodes = Dir.entries(parent_dir) - [".", ".."]
  dirs = nodes.select {|n| dir?(parent_dir, n) }.sort {|x, y| x <=> y }
  files = (nodes - dirs).sort {|x, y| x <=> y }
  files.each {|file| print_file(file, level) }
  dirs.each {|dir| tree(File.join(parent_dir, dir), level + 1) }
end

def dir?(parent_dir, node)
  File.directory?(File.join(parent_dir, node))
end

def dir_file_order(parent_dir, node)
  dir?(parent_dir, node) ? 1 : 0
end

def sort_by_node_type(nodes, parent_dir)
  nodes.map {|n| [dir_file_order(parent_dir, n), n] }.
    sort {|x, y| x <=> y }.
    map {|n| n[1] }
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

