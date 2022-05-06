# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/thing_mailer
class ThingMailerPreview < ActionMailer::Preview
  def preview_thing
    Thing.joins(:user).where('users.email' => 'john@example.com').first
  end

  def first_adoption_confirmation
    ThingMailer.first_adoption_confirmation(preview_thing)
  end

  def second_adoption_confirmation
    ThingMailer.second_adoption_confirmation(preview_thing)
  end

  def third_adoption_confirmation
    ThingMailer.third_adoption_confirmation(preview_thing)
  end
end
