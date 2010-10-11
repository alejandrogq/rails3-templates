puts "\r\n\r\n*****************************************************************************************************"
puts "Let me ask you a few questions before i start bootstrapping your app"
puts "*****************************************************************************************************"

hoptoad_key = ask("\r\n\r\nWant to use your Hoptoad Account?\n\r\n\rEnter your API Key, or press Enter to skip")
locale_str = ask("Enter a list of locales you want to use separated by commas (e.g. 'es, de, fr'). For a reference list visit http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/. Press enter to skip: ")
auth_gem = ask("\r\n\r\nWhat authentication framework do you want to use?\r\n\r\n(1) Devise\r\n(2) Authlogic")
if ["1", "2"].include?(auth_gem)
  auth = "devise" if auth_gem=="1"
  auth = "authlogic" if auth_gem=="2" 
else
  puts "Woops! You must enter a number between 1 and 4"
  ask_gem
end


puts "\r\n\r\n*****************************************************************************************************"
puts "All set. Bootstrapping your app!!"
puts "*****************************************************************************************************\r\n\r\n"

# GO!
run "rm -Rf .gitignore README public/index.html public/images/rails.png public/javascripts/* app/views/layouts/*"

gem 'will_paginate', '>=3.0.pre2'

gem "haml-rails", ">= 0.2"
gem "compass", ">= 0.10.5"
gem "compass-960-plugin"
gem 'inherited_resources', '~> 1.1.2'
gem "formtastic", '~> 1.1.0'
gem "attrtastic"

# other stuff
gem 'friendly_id', '~>3.1'

# development
gem "rails-erd", :group => :development
gem 'wirble', :group => :development
gem 'awesome_print', :group => :development
gem "hirb", :group => :development

# testing
gem "factory_girl_rails", :group => [:test, :cucumber]
gem "shoulda", :group => [:test, :shoulda]
gem "faker", :group => [:test, :cucumber]
gem "mynyml-redgreen", :group => :test, :require => "redgreen"

gem 'cucumber', ">=0.6.3", :group => :cucumber
gem 'cucumber-rails', ">=0.3.2", :group => :cucumber
gem 'capybara', ">=0.3.6", :group => :cucumber
gem 'database_cleaner', ">=0.5.0", :group => :cucumber
gem 'spork', ">=0.8.4", :group => :cucumber
gem "pickle", ">=0.4.2", :group => :cucumber
gem "launchy", :group => :cucumber

# staging & production stuff
gem 'pg', :group => :production
unless hoptoad_key.empty?
  gem "hoptoad_notifier", '~> 2.3.6'
  initializer 'hoptoad.rb', <<-FILE
HoptoadNotifier.configure do |config|
  config.api_key = '#{hoptoad_key}'
end
FILE
end

run "bundle install"

gem 'rails3-generators', :group => :development

plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'

application  <<-GENERATORS 
config.generators do |g|
  g.orm :active_record
  g.stylesheets false
  g.template_engine :haml
  g.test_framework  :shoulda, :fixture_replacement => :factory_girl
  g.fallbacks[:shoulda] = :test_unit
  g.integration_tool :cucumber
  g.form_builder :formtastic
  g.helper false
end
GENERATORS

# configure cucumber
generate "cucumber:install --capybara --testunit --spork"
generate "pickle --path --email"
get "http://github.com/aentos/rails3-templates/raw/master/within_steps.rb" ,"features/step_definitions/within_steps.rb" 

generate "friendly_id"
generate "formtastic:install"
run "gem install compass"
run "compass init -r ninesixty --using 960 --app rails --css-dir public/stylesheets"
create_file "app/stylesheets/_colors.scss"
run "rm public/stylesheets/*"

unless locale_str.empty?
  locales = locale_str.split(",")
  locales.each do |loc|
    get("http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{loc.strip}.yml", file)
  end
end

# formtastic sass mixins
get "http://github.com/activestylus/formtastic-sass/raw/master/_formtastic_base.sass", "app/stylesheets/_formtastic_base.sass"

# jquery
get "http://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"

get "http://github.com/aentos/rails3-templates/raw/master/gitignore" ,".gitignore" 

plugin 'annote_models', :git => "http://github.com/justinko/annotate_models.git"

# TODO: default stylesheets: screen & print
get "http://github.com/aentos/rails3-templates/raw/master/application.html.haml", "app/views/layouts/application.html.haml"
get "http://github.com/aentos/rails3-templates/raw/master/build.rake", "lib/tasks/build.rake"
get "http://github.com/aentos/rails3-templates/raw/master/asset_packages.yml", "config/asset_packages.yml"

create_file 'config/deploy.rb', <<-DEPLOY
application = '#{app_name}'
repository = ''
hosts = %w() 
DEPLOY

append_file 'Rakefile', <<-METRIC_FU
MetricFu::Configuration.run do |config|  
  config.rcov[:rcov_opts] << "-Ispec"  
end rescue nil
METRIC_FU

git :init
git :add => '.'
git :commit => '-am "Initial commit"'

apply "http://github.com/aentos/rails3-templates/raw/master/#{auth}.rb" unless auth.blank

puts "SUCCESS!"