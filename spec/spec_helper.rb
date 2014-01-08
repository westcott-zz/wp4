# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rubygems'
require 'capybara/rails'
require 'acts_as_fu'
require 'factory_girl'
#require 'factory_girl_rails'
require 'ffaker'
require 'coveralls'

require 'yaml'
Coveralls.wear!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true

  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

# Note: Authentication is NOT ActiveRecord model, so we mock and stub it using RSpec.
#----------------------------------------------------------------------------
def login(user_stubs = {}, session_stubs = {})
  User.current_user = @current_user = FactoryGirl.create(:user, user_stubs)
  @current_user_session = double(Authentication, {:record => current_user}.merge(session_stubs))
  Authentication.stub(:find).and_return(@current_user_session)
  #set_timezone
end
alias :require_user :login

##################################################

ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

# Load shared behavior modules to be included by Runner config.
Dir["./spec/shared/**/*.rb"].sort.each {|f| require f}

TICKET_STATUSES = %w(pending assigned completed).freeze

I18n.locale = 'en-US'

Paperclip.options[:log] = false

RSpec.configure do |config|

  config.mock_with :rspec

  config.fixture_path = "#{Rails.root}/spec/fixtures"

  # RSpec configuration options for Fat Free CRM.
  config.include RSpec::Rails::Matchers

  config.before(:each) do
    # Overwrite locale settings within "config/settings.yml" if necessary.
    # In order to ensure that test still pass if "Setting.locale" is not set to "en-US".
    I18n.locale = 'en-US'
    Setting.locale = 'en-US' unless Setting.locale == 'en-US'
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  config.before :all, :type => :feature do
    DatabaseCleaner.clean_with(:truncation)
  end
  config.around :each, :type => :feature do |example|
    DatabaseCleaner.strategy = :truncation
    example.run
    DatabaseCleaner.strategy = :transaction
  end
  config.around :each do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end

  # PaperTrail slows down tests so only turned on when needed.
  PaperTrail.enabled = false

  config.around :each, :type => :feature do |example|
    was_enabled = PaperTrail.enabled?
    PaperTrail.enabled = true
    PaperTrail.controller_info = {}
    PaperTrail.whodunnit = nil
    begin
      example.run
    ensure
      PaperTrail.enabled = was_enabled
    end
  end

  config.around :each, :versioning => true do |example|
    was_enabled = PaperTrail.enabled?
    PaperTrail.enabled = true
    PaperTrail.controller_info = {}
    PaperTrail.whodunnit = nil
    begin
      example.run
    ensure
      PaperTrail.enabled = was_enabled
    end
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end

ActionView::TestCase::TestController.class_eval do
  def controller_name
    HashWithIndifferentAccess.new(request.path_parameters)["controller"].split('/').last
  end
end

ActionView::Base.class_eval do
  def controller_name
    HashWithIndifferentAccess.new(request.path_parameters)["controller"].split('/').last
  end

  def called_from_index_page?(controller = controller_name)
    if controller != "tickets"
      request.referer =~ %r(/#{controller}$)
    else
      request.referer =~ /tickets\?*/
    end
  end

  def called_from_landing_page?(controller = controller_name)
    request.referer =~ %r(/#{controller}/\w+)
  end
end
