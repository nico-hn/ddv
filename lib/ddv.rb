#!/usr/bin/env ruby

require 'fileutils'

def tree(parent_dir, level=0)
  print_dir(File.basename(parent_dir), level)
  Dir.entries(parent_dir).each do |node|
    next if [".", ".."].include? node
    if File.directory?(File.join(parent_dir, node))
      tree(File.join(parent_dir, node), level + 1)
    else
      print "  " * level + "  *"
      puts node
    end
  end
end

def print_dir(dir, level)
  print "  " * level
  puts "[#{dir}]"
end

tree("test")

