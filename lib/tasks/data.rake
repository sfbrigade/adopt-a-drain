# frozen_string_literal: true

# from Savannah implementation
# run with:
# docker-compose run --rm web bundle exec rake data:load_drains[everett]
# or
# heroku rake data:load_drains[everett]

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task :load_drains, [:city] => :environment do |_t, args|
    city = args[:city]
    raise 'Must specify the city for which to load drain data' if city.nil?

    config = CityHelper.config(city).data
    columns = config.fetch(:columns)
    data_path = Rails.root.join 'config', 'cities', 'data', config.fetch(:file)
    raise "Missing data file #{data_path}" unless File.exist? data_path

    puts "There are #{Thing.for_city(city).count} drains for #{city}..."
    puts "Loading drains for #{city} from #{data_path} ..."
    csv_string = File.open(data_path).read
    drains = CSV.parse(csv_string, headers: true)
    puts "Loading #{drains.size} drains."

    # Update or create things listed in the input data
    total = 0
    drains.each_slice(1000) do |group|
      updated = 0
      created = 0
      group.each do |drain|
        id = drain.fetch(columns.fetch(:id))
        thing_hash = {
          name: columns.fetch(:name).map { |c| drain.fetch(c) }.join(' '),
          lat: drain.fetch(columns.fetch(:lat)),
          lng: drain.fetch(columns.fetch(:lng)),
          city_domain: city,
          city_id: id,
        }

        thing = Thing.for_city(city).where(city_id: id).first
        if thing
          # Don't update the name in case a user has renamed it
          thing.assign_attributes(thing_hash.slice(:lat, :lng))
          updated += 1 if thing.changed?
        else
          Thing.create(thing_hash)
          created += 1
        end

        total += 1
      end

      puts "updated/created: #{updated}/#{created} ... #{total}"
    end

    # Remove things not listed in the input data
    new_ids = drains.map { |d| d.fetch(columns.fetch(:id)) }
    existing_ids = Thing.for_city(city).select(:city_id).map(&:city_id)
    removed_ids = existing_ids.difference(new_ids)
    removed_ids.each_slice(100) do |ids|
      Thing.for_city(city).where(city_id: ids).destroy_all
    end
    puts "removed #{removed_ids.size} things"
  end
end
