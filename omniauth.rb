gem 'omniauth'
run 'bundle install'

create_file 'config/initializers/omniauth.rb', <<-FILE
Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :twitter, 'CONSUMER_KEY', 'CONSUMER_SECRET'
  #provider :facebook, 'APP_ID', 'APP_SECRET'
  #provider :linked_in, 'CONSUMER_KEY', 'CONSUMER_SECRET'
end
FILE

route "match '/auth/:provider/callback', :to => 'sessions#create'"
route "match '/logout', :to => 'sessions#destroy'"
generate "controller sessions"
generate "model authorization provider:string uid:string user_id:integer"
generate "model user name:string"

get "http://github.com/aentos/rails3-templates/raw/master/omniauth/user.rb", "app/models/user.rb"
get "http://github.com/aentos/rails3-templates/raw/master/omniauth/authorization.rb", 'app/models/authorization.rb'
get "http://github.com/aentos/rails3-templates/raw/master/omniauth/user_sessions_controller.rb", "app/controllers/application_controller.rb"
get "http://github.com/aentos/rails3-templates/raw/master/omniauth/application_controller", "app/controllers/application_controller.rb"