# frozen_string_literal: true

require 'test_helper'

class AdoptionsMailerTest < ActionMailer::TestCase
  test 'usage_report' do
    things(:thing_1).update(user: users(:erik))
    things(:thing_2).update(user: users(:dan))

    email = AdoptionsMailer.with(city: 'everett').usage_report.deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ['noreply@mysticdrains.org'], email.from
    assert_equal ['me@example.com'], email.to
    assert_match(/Usage Report/, email.subject)

    signups = email.attachments[0]
    signups_csv = signups.body.encoded
    # Correct filename
    assert_match(/signups.*csv/, signups.filename)
    # Header + 2 users
    assert_equal(3, signups_csv.lines.size)
    # Header row
    assert_match(/first_name/, signups_csv.lines[0])
    # Includes users from city
    assert_match(/erik@example.com/, signups_csv)
    # Excludes other users from other cities
    assert_no_match(/dan@example.com/, signups_csv)

    adoptions = email.attachments[1]
    adoptions_csv = adoptions.body.encoded

    # Correct filename
    assert_match(/adopted-drains.*csv/, adoptions.filename)
    # Header + 1 adoption
    assert_equal(2, adoptions_csv.lines.size)
    # Header row
    assert_match(/id/, adoptions_csv.lines[0])
    # Includes adoption from city
    assert_match(/\b1\b/, adoptions_csv.lines[1])
    # Excludes adoptions from other cities
    assert_no_match(/\b2\b/, adoptions_csv)

    assert City.where(name: 'everett').first!.last_export_time > Time.zone.now - 1.minute
  end
end
