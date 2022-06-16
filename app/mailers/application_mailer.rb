# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'Adopt a Drain Mystic River <noreply@mysticdrains.org>'
  layout 'mailer'
  helper CityHelper
end
