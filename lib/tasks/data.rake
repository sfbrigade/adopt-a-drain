# frozen_string_literal: true

# from Savannah implementation
# run with:
# docker-compose run --rm web bundle exec rake data:load_drains[everett]
# or
# heroku rake data:load_drains[everett]

namespace :data do
  task load_drains: :environment do
    cities = ENV.fetch('cities')
    cities = if cities == 'all'
               CityHelper.city_names
             else
               cities.split(' ').map { |c| CityHelper.check(c) }
             end
    loader = LoadDrains.new
    cities.each do |city|
      loader.load_drains(city)
    end
  end
end

class LoadDrains
  # - for each record in the temp table, locate matching records in the temp table (self-join to detect duplicates) and in the things table (detect existing records).
  # - no matching records = new
  # - 1 matching record = update
  # - > 1 matching record, duplicates in input = error
  # - things without matches = delete
  #
  # - Records match if id's match or they are within 3 feet of each other

  # Split into 3 bins: new (in csv and no existing), updated (in both), removed (not in csv but existing)
  def initialize
    @conn = ActiveRecord::Base.connection
  end

  def load_drains(city)
    @city = city
    @input = parse_input
    load_input_table
    @matches = match_drains
    clean_up
  end

  def match_drains
    check_no_input_duplicates
    matched_drains = match_input table: 'things', id_column: 'city_id', city: @city
  end

  def check_no_input_duplicates
    matched_input = match_input table: 'input', id_column: 'id'
    duplicates = matched_input.group_by { |m| m[:input_id] }.filter { |_k, v| v.size > 1 }
    p duplicates.size
    raise 'Duplicate input rows found' unless duplicates.empty?
  end

  def match_input(args = {})
    p 'about to match'
    city = args[:city]
    distance_in_feet = "earth_distance(
        ll_to_earth(input.lat, input.lng),
        ll_to_earth(drains.lat, drains.lng)
      ) * 3.28"
    records = ActiveRecord::Base.connection.execute <<-SQL
      SELECT
        input.id AS input_id,
        matched_record.id AS matched_record_id,
        matched_record.distance_in_feet as distance_in_feet
      FROM
        input
      LEFT JOIN LATERAL (
          SELECT
              drains.#{args[:id_column]} as id, #{distance_in_feet} as distance_in_feet
          FROM #{args[:table]} as drains
          WHERE #{"drains.city_domain = '#{city}' AND " if city}
              (drains.#{args[:id_column]} = input.id OR #{distance_in_feet} < 1.0)
        ) AS matched_record ON true
    SQL
    records
  end

  def clean_up
    @conn.execute('DROP TABLE "input"')
  end

  # Compare the input csv to existing things, based either on id or lat/lon locality
  # - Load input csv into a temporary table. Set id to uuid if not specified.
  def load_input_table
    insert_statement_id = SecureRandom.uuid

    @conn.execute(<<-SQL.strip_heredoc)
    CREATE TEMPORARY TABLE "input" (
      id varchar,
      name varchar,
      lat numeric(16,14),
      lng numeric(17,14),
      PRIMARY KEY(id)
    )
    SQL

    @conn.raw_connection.prepare(insert_statement_id, 'INSERT INTO input (id, name, lat, lng) VALUES($1, $2, $3, $4)')

    @input.each do |drain|
      @conn.raw_connection.exec_prepared(
        insert_statement_id,
        [drain[:id], drain[:name], drain[:lat], drain[:lng]],
      )
    end
  end

  def parse_input
    config = CityHelper.config(@city).data
    columns = config.fetch(:columns)
    data_path = Rails.root.join 'config', 'cities', 'data', config.fetch(:file)
    raise "Missing data file #{data_path}" unless File.exist? data_path

    csv_string = File.open(data_path).read
    drains = CSV.parse(csv_string, headers: true)

    drains.map do |drain|
      id = drain.fetch(columns.fetch(:id)).presence || SecureRandom.uuid
      name = if columns.key?(:name)
               columns.fetch(:name).map { |c| drain.fetch(c) }.join(' ')
             else
               'Storm Drain'
             end
      {
        id: id,
        name: name,
        lat: drain.fetch(columns.fetch(:lat)),
        lng: drain.fetch(columns.fetch(:lng)),
      }
    end
  end
end

def process_city(city)
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

      thing = Thing.with_deleted.for_city(city).where(city_id: id).first
      if thing
        # Don't update the name in case a user has renamed it
        thing.assign_attributes(thing_hash.slice(:lat, :lng))
        thing.deleted_at = nil
        if thing.changed?
          updated += 1
          thing.save!
        end
      else
        Thing.create!(thing_hash)
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
