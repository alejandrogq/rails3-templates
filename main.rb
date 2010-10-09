puts "Let me ask you a few questions before i start bootstrapping your app"
hoptoad_key = ask("\r\n\r\nWant to use your Hoptoad Account?\n\r\n\rEnter your API Key, or press Enter to skip")
locale_str = ask("Enter a list of locales you want to use separated by commas (e.g. 'es, de, fr'). For a reference list visit http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/. Press enter to skip: ")

puts "All set. Bootstrapping!!"

# GO!
run "rm -Rf .gitignore README public/index.html public/images/rails.png public/javascripts/* test app/views/layouts/*"

file ("config/example_database.yml") do
<<-FILE
  development:
    adapter: postgresql
    database: #{app_name}_development
    host: localhost
    username: #{app_name}
    password: #{app_name}
    timeout: 5000

  staging:
    adapter: postgresql
    database: #{app_name}_staging
    host: localhost
    username: #{app_name}
    password: #{app_name}
    timeout: 5000

  production:
    adapter: postgresql
    database: #{app_name}_production
    host: localhost
    username: #{app_name}
    password: #{app_name}
    timeout: 5000

  # Warning: The database defined as 'test' will be erased and
  # re-generated from your development database when you run 'rake'.
  # Do not set this db to the same as development or production.
  test: &test
    adapter: postgresql
    database: #{app_name}_test
    host: localhost
    username: #{app_name}
    password: #{app_name}
    timeout: 5000

  cucumber:
    <<: *test
FILE
end

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

# testing
gem "factory_girl_rails", :group => [:test, :cucumber]
gem "shoulda", :group => :test
gem "faker", :group => [:test, :cucumber]

gem 'cucumber', ">=0.6.3", :group => :cucumber
gem 'cucumber-rails', ">=0.3.2", :group => :cucumber
gem 'capybara', ">=0.3.6", :group => :cucumber
gem 'database_cleaner', ">=0.5.0", :group => :cucumber
gem 'spork', ">=0.8.4", :group => :cucumber
gem "pickle", ">=0.4.2", :group => :cucumber

# staging & production stuff
unless hoptoad_key.empty?
  gem "hoptoad_notifier", '~> 2.3.6'
  initializer 'hoptoad.rb', <<-FILE
HoptoadNotifier.configure do |config|
  config.api_key = '#{hoptoad_key}'
end
FILE
end

run "bundle install"

# asset packager FTW
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'

# TODO: rspec?!
application  <<-GENERATORS 
config.generators do |g|
  g.template_engine :haml
  g.test_framework  :shoulda
  g.fallbacks[:shoulda] = :test_unit
  g.integration_tool :cucumber
  g.fixture_replacement :factory_girl, :dir => "test/factories"
end
GENERATORS

generate "cucumber:install --capybara --testunit --spork"
generate "pickle --path --email"
generate "friendly_id"
generate "formtastic:install"
run "gem install compass"
run "compass init -r ninesixty --using 960 --app rails --css-dir public/stylesheets"

run "rm public/stylesheets/*"

unless locales.empty?
  locales = locale_str.split(",")
  locales.each do |loc|
    get("http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{loc.strip}.yml", file)
  end
end

# formtastic sass mixins
get "http://github.com/activestylus/formtastic-sass/raw/master/_formtastic_base.sass", "app/stylesheets/_formtastic_base.sass"

# jquery
get "http://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"

get "http://github.com/aentos/rails3_template/raw/master/gitignore" ,".gitignore" 

# TODO: default stylesheets: screen & print
get "http://github.com/aentos/rails3_templates/raw/master/application.html.haml", "app/views/layouts/application.html.haml"
get "http://github.com/aentos/rails3_templates/raw/master/build.rake", "lib/tasks/build.rake"
get "http://github.com/aentos/rails3_templates/raw/master/asset_packages.yml", "config/asset_packages.yml"

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
 
puts "SUCCESS!"