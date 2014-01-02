source 'https://rubygems.org'

gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'

gem 'fat_free_crm', :git => 'git://github.com/fatfreecrm/fat_free_crm.git'
#gem 'ff_ticket', :path => '/home/daniel/code/ff_ticket'
#gem 'ffcrm_merge', :github => 'fatfreecrm/ffcrm_merge'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :test, :development do
  gem 'ruby-debug',   :platform => :mri_18
  gem 'debugger',   :platform => :mri_19
  #gem 'turn'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'ruby-growl'
  gem 'launchy'

  gem 'capybara', '~> 2.0.3'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem "acts_as_fu"
  gem 'factory_girl_rails'
  gem 'zeus' unless ENV["CI"]
  gem 'coveralls', :require => false
end
# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
