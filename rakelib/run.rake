module RunLabs
  module_function
  
  def make_sample_name(lab_number, word)
    SAMPLES_DIR + ("/%03d_%s.txt" % [lab_number, word])
  end
  
  def run_command(command, var)
    command.gsub!(/<(\w+)>/) { |args, one| var[$1] }
    if command =~ /^cd +(\S+)$/
      dir = $1
      puts "Changing to '#{dir}'"
      Dir.chdir(dir)
      @command_output = ''
    else
      @command_output = `#{command}`
      puts @command_output
    end
  end

  def hash_for(pattern)
    hash = `git log --pretty=oneline`.split(/\n/).grep(/#{pattern}/).first[0,8] rescue ""
    fail "Invalid hash (#{hash}) for '#{pattern}'" unless hash =~ /^[0-9a-zA-Z]{8}$/
    hash
  end
  
  def hash_in(hash, pattern)
    lines = `git cat-file -p #{hash}`.split(/\n/)
    line = lines.grep(/#{pattern}/).first || ""
    md = /[0-9a-zA-Z]{40}/.match(line)
    fail "No hash found for /#{pattern}/ while dumping '#{hash}'" if md.nil?
    md[0]
  end
  
  def run_labs(source, last_lab)
    last_lab = last_lab.to_i if last_lab
    var = {}
    output_file = nil
    state = :seek
    lab_number = 0
    @command_output = ""
    while line = source.gets
      case state
      when :seek
        if line =~ /^Execute: *$/
          puts "EXECUTE"
          state = :execute
        elsif line =~ /^File: (\S+) *$/
          fn = $1
          puts "Create #{fn}"
          output_file = open(fn, "w")
          state = :file
        elsif line =~ /^-------------* *$/
          if last_lab && lab_number >= last_lab
            puts
            puts "** Stopping at Lab #{lab_number} **"
            puts
            break
          end
          lab_number += 1
          puts "** Lab #{lab_number} **********************************************************"
        elsif line =~ /^Set: +(\w+)=(.*)$/
          vname = $1
          code = $2
          var[vname] = eval(code)
          puts "SETTING: #{vname}='#{var[vname]}' (from #{code})"
        else
          puts "                #{line}"
        end
      when :file
        if line =~ /^EOF *$/
          output_file.close if output_file
          output_file = nil
          state = :seek
        else
          output_file.puts(line)
          puts "CONTENT: #{line}"
        end
      when :execute
        if line =~ /^ *$/
          state = :seek
        elsif line =~ /^=(\w+)/
          name = $1
          puts "CAPTURING: #{name}"
          sample_name = make_sample_name(lab_number, name)
          open(sample_name, "w") do |out|
            out.write(@command_output)
          end
        elsif line =~ /^!/
          line.sub!(/^!/,'')
          puts "RUNNING: <#{line.strip}>"
          run_command(line, var) rescue nil
        elsif line =~ /^-/
          puts "SKIPPING: <#{line.strip}>"
        else
          puts "RUNNING: <#{line.strip}>"
          line.sub!(/^\+/, '')
          run_command(line, var)
        end
      end
    end
  ensure
    output_file.close if output_file
  end
end


directory SAMPLES_DIR

desc "Run the labs automatically"
task :run, [:last_lab] => [SAMPLES_DIR] do |t, args|
  rm_r "auto" rescue nil
  mkdir_p "auto/hello"
  open("src/labs.txt") do |lab_source|
    Dir.chdir "auto/hello"
    RunLabs.run_labs(lab_source, args.last_lab)
  end
end
