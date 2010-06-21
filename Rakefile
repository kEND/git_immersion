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

task :not_dirty do
  fail "Directory not clean" if /nothing to commit/ !~ `git status`
end

task :publish => [:not_dirty, :labs] do
  sh 'git checkout master'
  head = `git log --pretty="%h" -n1`.strip
  sh 'git checkout gh-pages'
  cp FileList['git_tutorial/html/*.html'], '.'
  sh 'git add .'
  sh "git commit -m 'Updated docs to #{head}'"
  sh 'git push'
  sh 'git checkout master'
end
