# frozen_string_literal: true

# Load the Rails application.
require File.expand_path('application', __dir__)

# ActionMailer::Base.smtp_settings = {
#   address: 'smtp.sendgrid.net',
#   port: '587',
#   authentication: :plain,
#   user_name: ENV['SENDGRID_USERNAME'],
#   password: ENV['SENDGRID_PASSWORD'],
#   domain: 'heroku.com',
#   enable_starttls_auto: true,
# }

# from adopt-a-drain-savannah
ActionMailer::Base.smtp_settings = {
  address: ENV['MAILSERVER_HOST'],
  port: '587',
  authentication: :plain,
  user_name: ENV['MAILSERVER_USERNAME'],
  password: ENV['MAILSERVER_PASSWORD'],
  domain: ENV['MAILSERVER_DOMAIN'],
  enable_starttls_auto: true,
}

# Initialize the Rails application.
Rails.application.initialize!
