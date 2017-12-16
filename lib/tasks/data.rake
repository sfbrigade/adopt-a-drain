require 'rake'

namespace :data do
  task load_things: :environment do
    require 'thing_importer'

    ThingImporter.load('https://data.sfgov.org/api/views/jtgq-b7c5/rows.csv?accessType=DOWNLOAD')
  end

  task auto_adopt: :environment do
    # Make random users adopt drains to test server load when generating API data
    # There has to be users in DB for this to work

    if Rails.env.production?
        puts "Can't run this in production"
    else
      Thing.first(1000).each_with_index do |t, i|
        if t.user_id.blank?
          t.user_id = User.order('RANDOM()').limit(1).first.id
          t.save
        end
        puts i.to_s + " Adopting a drain"
      end
    end
  end
end
