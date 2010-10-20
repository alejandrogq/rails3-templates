puts "\r\n\r\n*****************************************************************************************************"
puts "Let me ask you a few questions before i start bootstrapping your app"
puts "*****************************************************************************************************"

hoptoad_key = ask("\r\n\r\nWant to use your Hoptoad Account?\n\r\n\rEnter your API Key, or press Enter to skip")
locale_str = ask("Enter a list of locales you want to use separated by commas (e.g. 'es, de, fr'). For a reference list visit http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/. Press enter to skip: ")
auth_option = ask("\r\n\r\nWhat authentication framework do you want to use?\r\n\r\n(1) Devise\r\n(2) Authlogic\r\n(3) Omniauth\r\nPress Enter to skip")
deploy_option = ask("\r\n\r\nWhat deploy method do you want to use?\r\n\r\n(1) Capistrano\r\n(2) Inploy\r\nPress Enter to skip")
css_framework_option = ask("\r\n\r\nWhat CSS framework do you want to use?\r\n\r\n(1) 960\r\n(2) Blueprint\r\nPress Enter for 960 (default)")
if ["1", "2", "3"].include?(auth_option)
  auth = "devise" if auth_option=="1"
  auth = "authlogic" if auth_option=="2"
  auth = "omniauth" if auth_option=="3"
else
  auth = nil
end

if ["1", "2"].include?(deploy_option)
  deploy = "capistrano" if deploy_option=="1"
  deploy = "inploy" if deploy_option=="2" 
else
  deploy = nil
end

if ["1", "2"].include?(css_framework_option)
  css_framework = "960" if css_framework_option=="1"
  css_framework = "blueprint" if css_framework_option=="2" 
else
  css_framework = "960"
end


puts "\r\n\r\n*****************************************************************************************************"
puts "All set. Bootstrapping your app!!"
puts "*****************************************************************************************************\r\n\r\n"

# GO!
run "rm -Rf .gitignore README public/index.html public/images/rails.png public/javascripts/* app/views/layouts/*"

gem 'will_paginate', '>=3.0.pre2'
gem "haml-rails", ">= 0.2"
gem "compass", ">= 0.10.5"
gem "fancy-buttons"
gem "compass-960-plugin" if css_framework=="960"
gem 'inherited_resources', '~> 1.1.2'
gem "simple_form"
gem "show_for"
gem "tabs_on_rails"
gem "meta_search"

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

gem 'rails3-generators', :group => :development

run "bundle install"

plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'

application  <<-GENERATORS 
config.generators do |g|
  g.orm :active_record
  g.stylesheets false
  g.template_engine :haml
  g.test_framework  :shoulda, :fixture_replacement => :factory_girl
  g.fallbacks[:shoulda] = :test_unit
  g.integration_tool :cucumber
  g.helper false
end
GENERATORS

# configure cucumber
generate "cucumber:install --capybara --testunit --spork"
generate "pickle --path --email"
get "http://github.com/aentos/rails3-templates/raw/master/within_steps.rb" ,"features/step_definitions/within_steps.rb" 

generate "friendly_id"
generate "simple_form:install -e haml"
generate "show_for:install"
file "lib/templates/haml/scaffold/show.html.haml", <<-FILE
= show_for @<%= singular_name %> do |s|
<% attributes.each do |attribute| -%>
  = s.<%= attribute.reference? ? :association : :attribute %> :<%= attribute.name %>
<% end -%>

== \#{link_to 'Edit', edit_<%= singular_name %>_path(@<%= singular_name %>) } | \#{ link_to 'Back', <%= plural_name %>_path }
FILE

# compass
run "gem install compass"
if css_framework=="960"
  run "compass init -r ninesixty --using 960 --app rails --css-dir public/stylesheets"
  get "http://github.com/aentos/rails3-templates/raw/master/application_960.html.haml", "app/views/layouts/application.html.haml"
  file "config/asset_packages.yml", <<-FILE
---
javascripts:
- base:
  - rails
stylesheets:
- screen:
  - grid
  - text
- handheld:
  - handheld
FILE
else
  run "compass init --using blueprint --app rails --css-dir public/stylesheets"
  get "http://github.com/aentos/rails3-templates/raw/master/application_blueprint.html.haml", "app/views/layouts/application.html.haml"
  file "config/asset_packages.yml", <<-FILE
---
javascripts:
- base:
  - rails
stylesheets:
- ie:
  - ie
- screen:
  - screen
- print:
  - print
- handheld:
  - handheld
FILE
end
create_file "app/stylesheets/_colors.scss"
get "http://github.com/aentos/rails3-templates/raw/master/handheld.scss" ,"app/stylesheets/handheld.scss" 

unless locale_str.empty?
  locales = locale_str.split(",")
  locales.each do |loc|
    get("http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{loc.strip}.yml", file)
  end
end

# jquery
get "http://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"

get "http://github.com/aentos/rails3-templates/raw/master/gitignore" ,".gitignore" 
get "http://github.com/aentos/rails3-templates/raw/master/build.rake", "lib/tasks/build.rake"

append_file 'Rakefile', <<-METRIC_FU
MetricFu::Configuration.run do |config|  
  config.rcov[:rcov_opts] << "-Ispec"  
end rescue nil
METRIC_FU

git :init
git :add => '.'
git :commit => '-am "Initial commit"'

apply "http://github.com/aentos/rails3-templates/raw/master/#{auth}.rb" unless auth.blank?
apply "http://github.com/aentos/rails3-templates/raw/master/#{deploy}.rb" unless deploy.blank?

puts "SUCCESS!"