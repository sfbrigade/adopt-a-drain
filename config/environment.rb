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
  # The address of the remote mail server
  address: ENV['MAILSERVER_HOST'],
  port: '587',
  authentication: :plain,
  # The email address of the sender account
  user_name: ENV['MAILSERVER_USERNAME'],
  # The password of the user_name
  password: ENV['MAILSERVER_PASSWORD'],
  # The domain of the sending host
  domain: ENV['MAILSERVER_DOMAIN'],
}

# Initialize the Rails application.
Rails.application.initialize!
