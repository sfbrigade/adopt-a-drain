# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/thing_mailer
class ThingMailerPreview < ActionMailer::Preview
  def first_adoption_confirmation
    ThingMailer.first_adoption_confirmation(Thing.for_city('everett').where.not(user: nil).first)
  end

  def second_adoption_confirmation
    ThingMailer.second_adoption_confirmation(Thing.for_city('everett').where.not(user: nil).first)
  end

  def third_adoption_confirmation
    ThingMailer.third_adoption_confirmation(Thing.for_city('everett').where.not(user: nil).first)
  end
end
