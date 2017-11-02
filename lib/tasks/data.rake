require 'rake'

namespace :data do
  task load_things: :environment do
    require 'thing_importer'

    ThingImporter.load('./norfolk.csv')
  end
end
