module Labs
  module_function
  
  HTML_DIR = 'git_tutorial/html'
  
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
  
  def make_sample_name(lab_number, word)
    SAMPLES_DIR + ("/%03d_%s.txt" % [lab_number, word])
  end
  
  def generate_labs(io)
    lab_index = -1
    labs = []
    mode = :direct
    gathered_line = ''
    io.each do |line|
      next if line =~ /^\s*-+\s*$/ # omit dividers
      next if line =~ /^[+][a-z]/  # omit hidden commands 
      line.sub!(/^[-!]/,'')        # remove force and execute ignore chars
      case mode
      when :direct
        if line =~ /^h1.\s+(.+)$/
          lab_index += 1
          lab = Lab.new($1, lab_index+1)
          lab.prev = labs.last
          labs.last.next = lab if labs.last
          lab.lines << line.sub(/h1\./, "h1. Lab #{lab_index+1}: ")
          labs << lab
        elsif line =~ /^pre*\(.*\)\.\s*$/
          mode = :gather1
          gathered_line = line.strip
        elsif line =~ /^p(\([(a-z){}]*)?\.\s+/
          mode = :gather
          gathered_line = line.strip
        elsif line =~ /^Execute:$/i
          mode = :gather1
          labs[lab_index] << "p(command). Execute:\n\n"
          gathered_line = "pre(instructions)."
        elsif line =~ /^File:\s+(\S+)$/i
          file_name = $1
          labs[lab_index] << "p(filename). File: #{file_name}\n\n"
          gathered_line = "<pre class=\"file\">"
          mode = :file
        elsif line =~ /^Output:\s*$/
          labs[lab_index] << "p(command). Output:\n\n"
          gathered_line = "<pre class=\"sample\">"
          mode = :file
        elsif line =~ /^Set: +\w+=.*$/
          # Skip set lines
        elsif line =~ /^=\w+/
          # Skip include lines
        else
          labs[lab_index] << line unless lab_index < 0
        end
      when :gather1
        labs[lab_index] << gathered_line << " " << line
        mode = :direct
      when :gather
        if line =~ /^\s*$/
          labs[lab_index] << gathered_line << "\n\n"
          mode = :direct
        else
          gathered_line << " " << line.strip
        end
      when :file
        if line =~ /^EOF$/
          labs[lab_index] << "</pre>\n"
          mode = :direct
        elsif line =~ /^=(\w+)/
          sample_name = make_sample_name(lab_index+1, $1)
          open(sample_name) do |ins|
            ins.each do |sample_line|
              labs[lab_index] << "#{gathered_line}#{sample_line}"
              gathered_line = ''
            end
          end
        else
          labs[lab_index] << "#{gathered_line}#{line}"
          gathered_line = ''
        end
      end
    end
    labs.each do |lab|
      to_html(lab)
    end
    index(labs)
  end
  
  def emit_links(f, lab)
    f.puts "<div class=\"nav\">"
    f.puts "<ul>"
    if lab.next
      f.puts "<li><a href=\"#{lab.next.filename}\">Next Lab</a></li>"
    else
      f.puts "<li>Next Lab</li>"
    end
    if lab.prev
      f.puts "<li><a href=\"#{lab.prev.filename}\">Previous Lab</a></li>"
    else
      f.puts "<li>Previous Lab</li>"
    end
    f.puts "<li><a href=\"index.html\">Index</a></li>"
    f.puts "</ul>"
    f.puts "</div>"
  end
  
  def index(labs)
    File.open("#{HTML_DIR}/index.html", "w") { |f| 
      f.puts "<html>"
      f.puts "<head>"
      f.puts "<link href=\"labs.css\" media=\"screen,print\" rel=\"stylesheet\" type=\"text/css\" />"
      f.puts "</head>"
      f.puts "<body>"
      f.puts "<div id=\"header\">"
      f.puts "<a href=\"http://edgecase.com\">"
      f.puts "<img id=\"logo\" src=\"edgecase.gif\"\ >"
      f.puts "</a>"
      f.puts "<h1 class=\"title\">Git Immersion Labs</h1>"
      f.puts "</div>"
      f.puts "<div id=\"main\">"
      f.puts "<h1>Index of Labs</h1>"
      f.puts "<ul>"
      labs.each do |lab|
        f.puts "<li><a href=\"#{lab.filename}\">Lab #{lab.number}</a>: #{lab.name}</li>"
      end
      f.puts "</ul>"
      f.puts "</div>"
      f.puts "<div id=\"footer\">"
      f.puts "</div>"
      f.puts "</body>"
      f.puts "</html>"
    }
  end

  def to_html(lab)
    lab_html = lab.to_html
    File.open("#{HTML_DIR}/#{lab.filename}", "w") { |f| 
      f.puts "<html>"
      f.puts "<head>"
      f.puts "<link href=\"labs.css\" media=\"screen,print\" rel=\"stylesheet\" type=\"text/css\" />"
      f.puts "</head>"
      f.puts "<body>"
      f.puts "<div id=\"header\">"
      f.puts "<a href=\"http://edgecase.com\">"
      f.puts "<img id=\"logo\" src=\"edgecase.gif\"\ >"
      f.puts "</a>"
      f.puts "<div class=\"title\">Git Immersion Labs</div>"
      emit_links(f, lab)
      f.puts "</div>"
      f.puts "<div id=\"main\">"
      f.puts "<div id=\"content\">"
      f.puts lab_html
      f.puts "</div>"
      f.puts "</div>"
      f.puts "<div id=\"footer\">"
      emit_links(f, lab)
      f.puts "</div>"
      f.puts "</body>"
      f.puts "</html>"
    }
  end
end

require 'rubygems'
require 'redcloth'
require 'rake/clean'

CLOBBER.include(Labs::HTML_DIR)

directory Labs::HTML_DIR

desc "Create the Lab HTML"
task :labs => [Labs::HTML_DIR, "src/labs.txt", "rakelib/labs.rake"] do |t|
  cp "src/labs.css", "#{Labs::HTML_DIR}/labs.css"
  cp "src/edgecase.gif", "#{Labs::HTML_DIR}/edgecase.gif"
  puts "Generating HTML"
  File.open("src/labs.txt") { |f| Labs.generate_labs(f) }
end

desc "View the Labs"
task :view do
  sh "open #{Labs::HTML_DIR}/index.html"
end
