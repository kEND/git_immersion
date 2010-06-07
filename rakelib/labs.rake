module Labs
  module_function
  
  class Lab
    attr_reader :name, :number, :lines
    attr_accessor :next, :prev

    def initialize(name, number)
      @name = name
      @number = number
      @lines = ""
    end

    def empty?
      @lines.empty?
    end

    def <<(line)
      @lines << line
    end

    def filename
      "lab_%02d.html" % number
    end

    def to_html
      RedCloth.new(lines).to_html
    end
  end
  
  def copy_line(line)
  end

  def generate_labs(io)
    lab_number = -1
    labs = []
    mode = :direct
    gathered_line = ''
    io.each do |line|
      next if line =~ /^\s*-+\s*$/
      case mode
      when :direct
        if line =~ /^h1.\s+(.+)$/
          lab_number += 1
          lab = Lab.new($1, lab_number)
          lab.prev = labs.last
          labs.last.next = lab if labs.last
          lab.lines << line.sub(/h1\./, "h1. Lab #{lab_number}: ")
          labs << lab
        elsif line =~ /^pre*\(.*\)\.\s*$/
          mode = :gather1
          gathered_line = line.strip
        elsif line =~ /^p[(a-z){}]*\.\s+/
          mode = :gather
          gathered_line = line.strip
        elsif line =~ /^Execute:$/
          mode = :gather1
          labs[lab_number] << "p(command). Execute:\n\n"
          gathered_line = "pre(instructions)."
        elsif line =~ /^File:\s+(\S+)$/
          file_name = $1
          labs[lab_number] << "p(filename). File: #{file_name}\n\n"
          gathered_line = "<pre class=\"file\">"
          mode = :file
        elsif line =~ /^Sample:\s*$/
          labs[lab_number] << "p(command). Sample:\n\n"
          gathered_line = "<pre class=\"sample\">"
          mode = :file
        else
          labs[lab_number] << line unless lab_number < 0
        end
      when :gather1
        labs[lab_number] << gathered_line << " " << line
        mode = :direct
      when :gather
        if line =~ /^\s*$/
          labs[lab_number] << gathered_line << "\n\n"
          mode = :direct
        else
          gathered_line << " " << line.strip
        end
      when :file
        if line =~ /^EOF$/
          labs[lab_number] << "</pre>\n"
          mode = :direct
        else
          labs[lab_number] << "#{gathered_line}#{line}"
          gathered_line = ''
        end
      end
    end
    labs.each do |lines|
      to_html(lines)
    end
    index(labs)
  end
  
  def emit_links(f, lab)
    if lab.next
      f.puts "<a href=\"#{lab.next.filename}\">Next Lab</a> | "
    else
      f.puts "Next Lab | "
    end
    if lab.prev
      f.puts "<a href=\"#{lab.prev.filename}\">Previous Lab</a> | "
    else
      f.puts "Previous Lab | "
    end
    f.puts "<a href=\"index.html\">Index</a>"
  end
  
  def index(labs)
    File.open("html/index.html", "w") { |f| 
      f.puts "<html>"
      f.puts "<head>"
      f.puts "<link href=\"labs.css\" media=\"screen,print\" rel=\"stylesheet\" type=\"text/css\" />"
      f.puts "</head>"
      f.puts "<body>"
      f.puts "<h1>Git Immersion Labs</h1>"
      f.puts "<ul>"
      labs.each_with_index do |lab, index|
        f.puts "<li><a href=\"#{lab.filename}\">Lab #{index}</a>: #{lab.name}</li>"
      end
      f.puts "</ul>"
      f.puts "</body>"
      f.puts "</html>"
    }
  end

  def to_html(lab)
    lab_html = lab.to_html
    File.open("html/#{lab.filename}", "w") { |f| 
      f.puts "<html>"
      f.puts "<head>"
      f.puts "<link href=\"labs.css\" media=\"screen,print\" rel=\"stylesheet\" type=\"text/css\" />"
      f.puts "</head>"
      f.puts "<body>"
      emit_links(f, lab)
      f.puts "<hr />"
      f.puts lab_html
      f.puts "<hr />"
      emit_links(f, lab)
      f.puts "</body>"
      f.puts "</html>"
    }
  end
end
  

require 'rubygems'
require 'redcloth'

directory "html"
task :labs => ["html", "src/labs.txt", "rakelib/labs.rake"] do |t|
  cp "src/labs.css", "html/labs.css"
  lab_source = File.open("src/labs.txt") { |f| Labs.generate_labs(f) }
end
