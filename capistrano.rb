gem "capistrano"
run "bundle install"
capify!

git :add => '.'
git :commit => '-m "Capistrano"'