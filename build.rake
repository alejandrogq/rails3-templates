task :clean do
  system "rm rerun.txt"
end

task :build => [:clean, 'db:migrate', :test, :cucumber, 'metrics:all', 'deploy']