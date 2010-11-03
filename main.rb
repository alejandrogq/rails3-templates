puts '\r\n\r\n*****************************************************************************************************'
puts 'Let me ask you a few questions before I start bootstrapping your app'
puts '*****************************************************************************************************'

auth_option = ask('\r\n\r\nWhat authentication framework do you want to use?\r\n\r\n(1) Devise\r\n(2) Authlogic\r\n(3) Omniauth\r\nPress Enter to skip')
deploy_option = ask('\r\n\r\nWhat deploy method do you want to use?\r\n\r\n(1) Capistrano\r\n(2) Inploy\r\nPress Enter to skip')
locale_str = ask('Enter a list of locales you want to use separated by commas (e.g. 'es, de, fr'). For a reference list visit http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/. Press enter to skip: ')
exceptions_option = ask('\r\n\r\nWhat exceptions tracker do you want to use?\r\n\r\n(1) Exceptional\r\n(2) Hoptoad\r\nPress Enter to skip')

if ['1', '2', '3'].include?(auth_option)
  auth = 'devise' if auth_option=='1'
  auth = 'authlogic' if auth_option=='2'
  auth = 'omniauth' if auth_option=='3'
else
  auth = nil
end

if ['1', '2'].include?(deploy_option)
  deploy = 'capistrano' if deploy_option=='1'
  deploy = 'inploy' if deploy_option=='2' 
else
  deploy = nil
end

if ['1', '2'].include?(exceptions_option)
  exceptions_tracker = 'exceptional' if css_framework_option=='1'
  exceptions_tracker = 'hoptoad' if css_framework_option=='2' 
else
  exceptions_tracker = nil
end

puts '\r\n\r\n*****************************************************************************************************'
puts 'All set. Bootstrapping your app!!'
puts '*****************************************************************************************************\r\n\r\n'

# GO!
run 'rm -Rf .gitignore README public/index.html public/images/rails.png public/javascripts/* app/views/layouts/*'

# gems
gem 'haml-rails', '>= 0.2'
gem 'inherited_resources', '~> 1.1.2'
gem 'friendly_id', '~>3.1'
gem 'compass', '>= 0.10.5'
gem 'fancy-buttons'
gem 'simple_form'
gem 'show_for'
gem 'will_paginate', '>=3.0.pre2'
gem 'tabs_on_rails'
gem 'breadcrumbs_on_rails'
gem 'paperclip'
gem 'meta_search'

# development
gem 'rails3-generators', :group => :development
gem 'rails-erd', :group => :development
gem 'wirble', :group => :development
gem 'awesome_print', :group => :development
gem 'hirb', :group => :development

# testing
gem 'factory_girl_rails', :group => [:test, :cucumber]
gem 'shoulda', :group => [:test, :shoulda]
gem 'faker', :group => [:test, :cucumber]
gem 'mynyml-redgreen', :group => :test, :require => 'redgreen'

gem 'cucumber', '>=0.6.3', :group => :cucumber
gem 'cucumber-rails', '>=0.3.2', :group => :cucumber
gem 'capybara', '>=0.3.6', :group => :cucumber
gem 'database_cleaner', '>=0.5.0', :group => :cucumber
gem 'spork', '>=0.8.4', :group => :cucumber
gem 'pickle', '>=0.4.2', :group => :cucumber
gem 'launchy', :group => :cucumber

# staging & production stuff
gem 'whenever', :group => :production
gem 'backup', :group => :production

if exceptions_tracker == 'hoptoad'
  gem 'hoptoad_notifier', '~> 2.3.6'
  initializer 'hoptoad.rb', <<-FILE
HoptoadNotifier.configure do |config|
  config.api_key = '#{hoptoad_key}'
end
FILE
end

if exceptions_tracker == 'exceptional'
  gem 'exceptional'
  exceptional install exceptional_key
end

run 'bundle install'

# plugins
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'

# generators
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
generate 'cucumber:install --capybara --testunit --spork'
generate 'pickle --path --email'
get 'http://github.com/recrea/rails3-templates/raw/master/within_steps.rb' ,'features/step_definitions/within_steps.rb' 

# configure other gems
generate 'friendly_id'
generate 'simple_form:install -e haml'
generate 'show_for:install'
file 'lib/templates/haml/scaffold/show.html.haml', <<-FILE
= show_for @<%= singular_name %> do |a|
<% attributes.each do |attribute| -%>
  = a.<%= attribute.reference? ? :association : :attribute %> :<%= attribute.name %>
<% end -%>

== \#{link_to 'Edit', edit_<%= singular_name %>_path(@<%= singular_name %>) } | \#{ link_to 'Back', <%= plural_name %>_path }
FILE
run 'wheneverize .'

# configure compass
run 'gem install compass'
run 'compass init --using blueprint --app rails --css-dir public/stylesheets'
create_file 'app/stylesheets/partials/_colors.scss'
get 'http://github.com/recrea/rails3-templates/raw/master/handheld.scss' ,'app/stylesheets/handheld.scss' 

get 'http://github.com/recrea/rails3-templates/raw/master/application.html.haml', 'app/views/layouts/application.html.haml'
file 'config/asset_packages.yml', <<-FILE
---
javascripts:
- base:
  - jquery.rails
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

# get locales
unless locale_str.empty?
  locales = locale_str.split(',')
  locales.each do |loc|
    get('http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{loc.strip}.yml', file)
  end
end

# get jquery
get 'http://github.com/rails/jquery-ujs/raw/master/src/rails.js', 'public/javascripts/jquery.rails.js'

# other stuff
get 'http://github.com/recrea/rails3-templates/raw/master/gitignore' ,'.gitignore' 
get 'http://github.com/recrea/rails3-templates/raw/master/build.rake', 'lib/tasks/build.rake'

append_file 'Rakefile', <<-METRIC_FU
MetricFu::Configuration.run do |config|  
  config.rcov[:rcov_opts] << '-Ispec'  
end rescue nil
METRIC_FU

git :init
git :add => '.'
git :commit => '-am 'Initial commit''

apply 'http://github.com/recrea/rails3-templates/raw/master/#{auth}.rb' unless auth.blank?
apply 'http://github.com/recrea/rails3-templates/raw/master/#{deploy}.rb' unless deploy.blank?

puts 'SUCCESS!'