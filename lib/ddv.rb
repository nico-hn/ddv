#!/usr/bin/env ruby

require 'fileutils'

def tree(parent_dir, level=0)
  print "  " * level
  puts "[#{File.basename(parent_dir)}]"
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

tree("test")

