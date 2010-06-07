task :default => :labs

task :delete_html do
  rm_r "git_tutorial/html"
end

task :rebuild => [:delete_html, :labs]
