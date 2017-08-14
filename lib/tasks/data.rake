require 'rake'

namespace :data do
  task load_things: :environment do
    require 'thing_importer'

    ThingImporter.load('https://data.sfgov.org/api/views/jtgq-b7c5/rows.csv?accessType=DOWNLOAD')
  end

  task auto_adopt: :environment do
    # Make random users adopt drains to test server load when generating API data
    # There has to be users in DB for this to work

    unless Rails.env.production?
      Thing.first(10_000).each do |t|
        if t.user_id.blank?
          t.user_id = User.find_by('id' => Random.rand(1..User.last.id)).id
          t.save
        end
      end
    end
  end
end
