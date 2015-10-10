#!/usr/bin/env ruby

require "ddv/version"
require 'fileutils'
require 'nokogiri'
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

      opt.on("-s [minimum_file_size]",
             "--minimum-file-size [=minimum_file_size]",
             "Specify the minimun size of files to report") do |size|
        options[:minimum_file_size] = size.to_i
      end

      opt.on("-l",
             "--link-check",
             "Check links in HTML files.") do |should_check_links|
        options[:link_check] = true if should_check_links
      end

      opt.on("-d [domain_name]",
             "--domain [domain_name]",
             "Specify the domain name") do |domain_name|
        options[:domain_name] = domain_name
      end

      opt.parse!
    end
    options
  end

  private_class_method :parse_command_line_options

  def self.execute
    options = parse_command_line_options
    if file_size = options[:minimum_file_size]
      printer = FileSizeChecker.new(file_size)
    end
    printer ||= NodePrinter.new(options[:max_detailed_files_num],
                              options[:ignore_file_type])
    directory = ARGV[0] || "."
    DirVisitor.new(printer).tree(directory)

    if options[:link_check]
      puts
      puts "==== Check links:"
      DirVisitor.new(LinkChecker.new(options[:domain_name])).tree(directory)
    end
  end

  class DirNode
    attr_reader :basename, :path

    def initialize(path)
      @path = path
      @basename = File.basename(path)
    end

    def to_s
      @path
    end

    alias to_str to_s
  end

  class FileNode
    attr_reader :basename, :path

    def initialize(parent_dir, basename)
      @path = File.join(parent_dir, basename)
      @basename = basename
    end

    def to_s
      @basename
    end

    alias to_str to_s
  end

  class DirVisitor
    def initialize(output=NodePrinter.new)
      @output = output
    end

    def tree(parent_dir, level=0)
      @output.output_dir(File.basename(parent_dir), level, parent_dir)
      nodes = Dir.entries(parent_dir) - [".", ".."]
      dirs, files = nodes.partition {|n| dir?(parent_dir, n) }.map(&:sort)
      @output.output_files(files, level, parent_dir)
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

    def output_files(files, level, parent_dir)
      if @max_detailed_files_num and files.size > @max_detailed_files_num
        output_files_summary(files)
      else
        puts
        files.each {|file| output_file(file, level) }
      end
    end
    
    def output_dir(dir, level, parent_dir)
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

  class FileSizeChecker < NodePrinter
    def initialize(minimum_size=0, maximum_size=nil)
      @units = { "B" => 1, "KB" => 1000, "MB" => 1000_000 }
      if maximum_size and maximum_size < minimum_size
        @minimum_size, @maximum_size = maximum_size, minimum_size
      else
        @minimum_size, @maximum_size = minimum_size, maximum_size
      end
    end

    def output_files(files, level, parent_dir)
      files_with_size = select_files(parent_dir, files)
      puts
      files_with_size.each do |file, size|
        output_file(file, level, size)
      end
    end

    private

    def file_size(parent_dir, file)
      File.size(File.join(parent_dir, file))
    end

    def select_files(parent_dir, files)
      files_with_size = files.map {|file| [file, file_size(parent_dir, file)] }
      smaller_removed = files_with_size.select {|f| f[1] >= @minimum_size }
      if @maximum_size
        smaller_removed.select {|f| f[1] <= @maximum_size }
      else
        smaller_removed
      end
    end

    def size_with_unit(size)
      return format("%dB", size) if size < 1000
      unit = size < 1000_000 ? "KB" : "MB"
      format("%.2f%s", size.to_f / @units[unit], unit)
    end

    def output_file(file, level, size)
      print "  " * level + "  * "
      print file
      puts " -> " + size_with_unit(size)
    end
  end

  class LinkChecker < NodePrinter
    PDF_SIZE_RE = /\[PDF +[1-9][0-9,]*[KM]?B\]/i

    def initialize(domain_name)
      @domain_name_re = compile_domain_name_re(domain_name)
    end

    def output_files(files, level, parent_dir)
      htmls = files.select {|file| /.html?$/ =~ file }
      htmls.each do |html|
        html_doc = read_html(parent_dir, html)
        pdf_links = select_pdf_links(parent_dir, html, html_doc)
        report_pdf_links(pdf_links)
        report_non_conformant_pdf_links(pdf_links)
        report_external_links(parent_dir, html, html_doc.xpath("//a"))
        report_title(parent_dir, html, html_doc)
      end
    end

    def output_dir(dir, level, parent_dir)
    end

    private

    def compile_domain_name_re(domain_name)
      return unless domain_name
      domain_name = Regexp.escape(domain_name)
      if domain_name.start_with?("http://", "https://")
        Regexp.compile(domain_name.sub(/https?:\/\//, "https?:\/\/"))
      else
        /https?:\/\/#{domain_name}/
      end
    end

    def read_html(parent_dir, html)
      Nokogiri::HTML(File.read(File.join(parent_dir, html)))
    end

    def select_pdf_links(parent_dir, html, html_doc)
      pdf_links = html_doc.xpath("//a").select {|a| /.pdf$/i =~ a["href"] }
      return pdf_links if pdf_links.empty?
      puts
      puts
      puts "-- Pdfs in #{File.join(parent_dir, html)}:"
      pdf_links
    end

    def report_pdf_links(pdf_links)
      pdf_links.each do |a|
        puts a.children.to_s
      end
    end

    def report_non_conformant_pdf_links(pdf_links)
      pdf_links.select do |a|
        PDF_SIZE_RE !~ a.children.to_s.chomp
      end.each do |a|
        puts format("|| The size is not indicated: %s", a.children.to_s)
      end
    end

    def external_url?(url)
      return unless @domain_name_re
      return unless url
      url.start_with?("http://", "https://") and @domain_name_re !~ url
    end

    def report_external_links(parent_dir, html, links)
      external_links = links.select {|a| external_url?(a["href"]) }
      print_header(external_links, "External links", parent_dir, html)
      external_links.each do |a|
        puts format("  %s | %s", a.children.to_s, a["href"])
      end
    end

    def report_title(parent_dir, html, html_doc)
      titles = html_doc.xpath("//title")
      h1 = html_doc.xpath("//h1")
      print_header(titles, "Title", parent_dir, html)
      titles.each do |title|
        puts title.children
      end
      h1.each do |h1|
        puts h1
      end
    end

    def print_header(items, label, parent_dir, html)
      unless items.empty?
        puts
        puts "== #{label} in #{File.join(parent_dir, html)}:"
      end
    end
  end
end

if $0 == __FILE__
  Ddv.execute
end
