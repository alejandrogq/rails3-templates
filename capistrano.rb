gem "capistrano"
run "bundle install"
capify!

app_name = ask "\r\n\r\nEnter the application name:"
server = ask "\r\n\r\nEnter the servername or IP:"
git_repo = ask "\r\n\r\nEnter the git repo URL, e.g. git@github.com:aentos/app.git :"

file 'config/deploy.rb', <<-FILE
# Bundler Integration
# http://github.com/carlhuda/bundler/blob/master/lib/bundler/capistrano.rb
require 'bundler/capistrano'

# Application Settings
set :application,   "#{app_name}"
set :user,          "deployer"
set :password,      "deployer"
set :deploy_to,     "/var/rails/#{app_name}"
set :rails_env,     "production"
set :use_sudo,      false
set :keep_releases, 5

# Git Settings
set :scm,           :git
set :branch,        "master"
set :repository,    "#{git_repo}"
set :deploy_via,    :remote_cache

# Uses local instead of remote server keys, good for github ssh key deploy.
ssh_options[:forward_agent] = true

# Server Roles
role :web, "#{server}"
role :app, "#{server}"
role :db,  "#{server}", :primary => true

# Passenger Deploy Reconfigure
namespace :deploy do
  desc "Restart passenger process"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch \#{current_path}/tmp/restart.txt"
  end
 
  [:start, :stop].each do |t|
    desc "\#{t} does nothing for passenger"
    task t, :roles => :app do ; end
  end
end
FILE
git :add => '.'
git :commit => '-m "Capistrano"'