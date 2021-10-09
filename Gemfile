source 'http://rubygems.org'
ruby File.read('.ruby-version').strip

# update mimemagic to account for yanked version in rails dependency
gem 'mimemagic', '~> 0.3.7'

# the base rails libraries
gem 'pg','~> 0.21'
gem 'rails', '4.2.8'
gem 'rails_12factor'
gem 'thin'
gem 'protected_attributes'



# for handling json objects with ruby
gem 'json'

gem 'bootstrap-sass', '~> 3.4.1'
gem 'coffee-rails'
gem 'font-awesome-sass', '~> 5.12.0'
gem 'jquery-rails'
gem 'sass-rails'
gem 'simple_form', '~> 4.0.0'
gem 'therubyracer', platforms: :ruby
gem 'twitter-bootstrap-rails'
gem 'uglifier'

gem 'momentjs-rails'
gem 'bootstrap3-datetimepicker-rails'
gem 'simple_calendar'

gem 'unicorn-rails'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'faker', '~> 1.7.3'
  gem 'guard-rspec', require: false
  gem 'rails-erd'
  gem 'rb-fsevent', '~> 0.9.0', require: false # latest 0.10.x seems to be incompatible with listen gem
  gem 'rubocop', require: false
end

group :development, :test do
  gem 'awesome_print'
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'rb-readline'
  gem 'sqlite3' # REMOVE THIS WHEN POSSIBLE
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'factory_girl_rails'
  gem 'poltergeist', '~> 1.12'
  gem 'rack-test'
  gem 'rspec-rails', '~> 3.5'
end
# Temporary fix: https://stackoverflow.com/questions/13828889/rails-3-heroku-cannot-load-such-file-test-unit-testcase-loaderror
# Remove after upgrade of Rails from 3.2 is complete.
gem 'test-unit', '~> 3.0'

# dynamic in-place editing for some admin tables
gem 'active_scaffold'

# handles authentication
gem 'devise', git: 'https://github.com/plataformatec/devise' , branch: '3-stable'

# lets us post things to twitter programatically
gem 'twitter'
gem 'yaml_db'

# smart image attachment management
gem 'aws-sdk-s3'
gem "kt-paperclip", "~> 6.4", ">= 6.4.1"

# generate pdfs
gem 'prawn', '~> 2.1.0'
gem 'prawn-table', '~> 0.2.2'

# used to geo-locate locations
gem 'addressable'
gem 'geocoder'
gem 'gmaps4rails', '1.5.6'

# lets us render charts in-browser
gem 'highcharts-rails', '~> 3.0.0'

# gives us pretty data tables
gem 'jquery-datatables-rails', git: 'https://github.com/rweng/jquery-datatables-rails.git'

# nested selecitons of volunteers on schedules
gem 'cocoon'

# set timezone to browser timezone
gem 'browser-timezone-rails' # '~> 0.0.9'
gem 'ranked-model'

# Send email when exception occurs.
gem 'exception_notification', '~> 4.2.2'
gem 'exception_notification-rake', '~> 0.3.0'

gem 'cancancan'
gem 'interactor'
gem 'newrelic_rpm'
