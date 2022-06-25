# frozen_string_literal: true

class AdoptionsMailerPreview < ActionMailer::Preview
  def usage_report
    AdoptionsMailer.with(city: 'everett').usage_report
  end
end
