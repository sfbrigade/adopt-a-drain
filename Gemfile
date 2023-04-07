# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.8'

gem 'airbrake', '~> 10.0'
gem 'devise', '~> 4.7'
gem 'geokit', '~> 1.13'
gem 'haml', '~> 5.1'
gem 'http_accept_language', '~> 2.0'
gem 'local_time', '~> 2.1'
gem 'obscenity', '~> 1.0', '>= 1.0.2'
gem 'pg'
gem 'rails', '~> 5.2.3'
gem 'rails_admin', '~> 2.0'
gem 'validates_formatting_of', '~> 0.9.0'

gem 'paranoia', '~> 2.4'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw]

gem 'dotenv-rails', groups: %i[development test]

group :assets do
  gem 'sass-rails', '>= 4.0.3'
  gem 'uglifier'
end

group :production do
  gem 'puma'
  gem 'rails_12factor'
  gem 'skylight'
end

group :test do
  gem 'capybara', '~> 3.39'
  gem 'rails-controller-testing' # TODO: remove and replace usages
  gem 'rubocop-rails'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webmock'
end
