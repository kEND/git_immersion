#!/usr/bin/ruby -wKU

require 'rake/clean'

SAMPLES_DIR = Dir.pwd + "/samples"

desc "Clean the samples directory"
task :clean_samples do
  rm_r SAMPLES_DIR rescue nil
end

task :default => :labs

task :rebuild => [:clobber, :labs]

task :see => [:rebuild, :view]
