# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Adopt a Drain Mystic River <todo@example.com>'
  layout 'mailer'
  helper CityHelper
end
