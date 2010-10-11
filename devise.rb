gem 'devise', '>=1.1.2'
run "bundle install"

generate "devise:install"
generate "devise User"
generate "devise Admin"