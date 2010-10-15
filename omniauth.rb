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

file "app/models/user.rb", <<-FILE
class User < ActiveRecord::Base
  has_many :authorizations
  
  def self.create_from_hash!(hash)
    create(:name => hash['user_info']['name'])
  end
  
end
FILE

file 'app/models/authorization', <<-FILE
class Authorization < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id, :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider
  
  def self.find_from_hash(hash)
    find_by_provider_and_uid(hash['provider'], hash['uid'])
  end

  def self.create_from_hash(hash, user = nil)
    user ||= User.create_from_hash!(hash)
    Authorization.create(:user => user, :uid => hash['uid'], :provider => hash['provider'])
  end
  
end
FILE

file 'app/controllers/user_sessions_controller.rb', <<-FILE
class UserSessionsController < InheritedResources::Base
  def create
    auth = request.env['rack.auth']
    unless @auth = Authorization.find_from_hash(auth)
      # Create a new user or add an auth to existing user, depending on
      # whether there is already a user signed in.
      @auth = Authorization.create_from_hash(auth, current_user)
    end
    # Log the authorizing user in.
    self.current_user = @auth.user

    render :text => "Welcome, #{current_user.name}."
  end
  
  def destroy
    session[:user_id] = nil
  end
end
FILE

file 'app/controllers/application_controller.rb', <<-FILE
class ApplicationController < ActionController::Base
  protect_from_forgery
  protected

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def signed_in?
    !!current_user
  end

  helper_method :current_user, :signed_in?

  def current_user=(user)
    @current_user = user
    session[:user_id] = user.id
  end
  
end
FILE