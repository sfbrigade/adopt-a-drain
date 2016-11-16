User.where(email: 'john@example.com').first_or_initialize.tap do |user|
  user.first_name = 'John'
  user.last_name = 'Doe'
  user.password = 'password'
end

r = Random.new

500.times do |i|
  Thing.where(city_id: i).first_or_initialize.tap do |thing|
    thing.name = "Some Drain #{i}"
    thing.lat = r.rand(35.90..36.10)
    thing.lng = r.rand(-79.10..-78.90)
    thing.system_use_code = ['MS4', 'STORM', 'COMB', 'UNK'].sample
    thing.save!
  end
end
