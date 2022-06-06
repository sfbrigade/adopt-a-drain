# frozen_string_literal: true

normal_user = User.where(email: 'john@example.com').first_or_initialize.tap do |user|
  user.first_name = 'John'
  user.last_name = 'Doe'
  user.password = 'password'
  user.save!
end

User.where(email: 'admin@example.com').first_or_initialize.tap do |user|
  user.first_name = 'Jane'
  user.last_name = 'Doe'
  user.password = 'password'
  user.admin = true
  user.save!
end

r = Random.new

500.times do |i|
  Thing.with_deleted.where(city_id: "seed-#{i}").first_or_initialize.tap do |thing|
    thing.name = "Some Drain #{i}"
    thing.lat = r.rand(37.75..37.78)
    thing.lng = r.rand(-122.43..-122.41)
    thing.system_use_code = %w[MS4 STORM COMB UNK].sample
    thing.city_domain = 'everett'
    thing.user_id = i < 5 ? normal_user.id : nil
    thing.priority = [true, false].sample
    thing.deleted_at = nil
    thing.save!
  end
end
