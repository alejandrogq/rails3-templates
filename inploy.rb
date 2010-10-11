gem 'inploy', '>=1.6.8'
create_file 'config/deploy.rb', <<-DEPLOY
application = '#{app_name}'
repository = ''
hosts = %w() 
DEPLOY
