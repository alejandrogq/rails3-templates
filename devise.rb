gem 'devise', '>=1.1.2'
run "bundle install"

generate "devise:install"

git :add => '.'
git :commit => '-m "devise"'