# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength

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
    dry_run = ENV['apply'] != 'true'
    loader = LoadDrains.new(dry_run)
    cities.each do |city|
      loader.load_drains(city)
    end
  end
end

class LoadDrains
  # Split into 3 bins: new (in csv and no existing), updated (in both), removed (not in csv but existing)
  def initialize(dry_run)
    @dry_run = dry_run
    @conn = ActiveRecord::Base.connection
  end

  def load_drains(city)
    @city = city

    puts
    puts 'Dry Run' if @dry_run
    puts "Loading drains for #{@city}"

    @input = parse_input
    load_input_table
    load_existing_table
    @matches = match_drains
    process_matches
    clean_up
  end

  # - for each record in the temp table, locate matching records in the temp
  #   table (self-join to detect duplicates) and in the things table (detect
  #   existing records). Records match if id's match or they are within 1 foot
  #   of each other
  # - no matching records = new
  # - 1 matching record = update
  # - > 1 matching record, duplicates in input = error
  # - things without matches = delete
  def match_drains
    puts 'Matching...'
    check_no_duplicate_inputs
    match_existing
  end

  def process_matches
    if @dry_run
      puts "#{@matches[:conflicts].size} conflicting matches: #{@matches[:conflicts]}"
      puts "#{@matches[:new_input_ids].size} new drains"
      puts "#{@matches[:updated].size} updated drains"
      puts "#{@matches[:removed_existing_ids].size} removed drains: #{@matches[:removed_existing_ids]}"
    else
      apply_matches
    end
  end

  def apply_matches
    raise "Conflicting matches: #{@matches[:conflicts]}" unless @matches[:conflicts].empty?

    thing_hashes = @inputs.map do |i|
      [i[:id], {
        name: i[:name],
        lat: i[:lat],
        lng: i[:lng],
        city_domain: @city,
        city_id: i[:id],
      }]
    end.to_h

    @matches[:new_input_ids].each do |id|
      Thing.create!(thing_hashes.fetch(id))
    end

    @matches[:updated].each do |d|
      thing = Thing.with_deleted.for_city(@city).where(city_id: d['matched_record_id']).first!
      # Update the city_id to allow adding id's later
      thing.assign_attributes(thing_hash.slice(:lat, :lng, :city_id))
      thing.deleted_at = nil
      thing.save! if thing.changed?
    end

    @matches[:removed_existing_ids].each_slice(100) do |ids|
      Thing.for_city(city).where(city_id: ids).destroy_all
    end
  end

  def match_existing
    matched = match_input 'existing'
    updated = matched.filter { |_k, v| v.size == 1 }.map { |_k, v| v[0] }
    existing_ids = Thing.for_city(@city).select(:city_id).map(&:city_id)
    updated_existing_ids = updated.map { |u| u['matched_record_id'] }
    {
      new_input_ids: matched.filter { |_k, v| v.empty? }.keys,
      updated: updated,
      conflicts: matched.filter { |_k, v| v.size > 1 },
      removed_existing_ids: existing_ids.difference(updated_existing_ids),
    }
  end

  def check_no_duplicate_inputs
    matched_input = match_input 'input'
    duplicates = matched_input.filter { |_k, v| v.size > 1 }
    return if duplicates.empty?

    puts "Duplicate input rows found \n#{duplicates.map { |k, v| "#{k}: #{v}" }.join("\n\n")}"
    raise 'Duplicate input found' unless @dry_run
  end

  def match_input(table, max_colocation_ft = 1.0)
    feet_per_meter = 3.28
    records = ActiveRecord::Base.connection.execute <<-SQL
      SELECT
        input.id AS input_id,
        matched_record.id AS matched_record_id,
        ST_Distance(input.location, matched_record.location) * #{feet_per_meter} as distance_in_feet
      FROM input
      LEFT JOIN LATERAL (
        SELECT id, location
        FROM #{table} as drains
        WHERE
          drains.id = input.id OR
          ST_DWithin(drains.location, input.location, #{max_colocation_ft.to_f / feet_per_meter})
      ) AS matched_record ON true
    SQL

    records.group_by { |m| m['input_id'] }.map { |k, v| [k, v.filter { |x| !x.nil? }] }.to_h
  end

  def clean_up
    @conn.execute('DROP TABLE "input"')
    @conn.execute('DROP TABLE "existing"')
  end

  # Compare the input csv to existing things, based either on id or lat/lon locality
  # - Load input csv into a temporary table. Set id to uuid if not specified.
  def load_input_table
    statement_id = SecureRandom.uuid

    @conn.execute <<-SQL
      CREATE TEMPORARY TABLE "input" (
        id varchar,
        name varchar,
        location geography(POINT),
        PRIMARY KEY(id)
      );
      CREATE INDEX input_locations ON input USING GIST ( location );
    SQL

    @conn.raw_connection.prepare statement_id, <<-SQL
      INSERT INTO input (id, name, location)
        VALUES ($1, $2,ST_SetSRID(ST_MakePoint($3, $4), 4326))
    SQL

    @input.each do |drain|
      @conn.raw_connection.exec_prepared(
        statement_id,
        [drain[:id], drain[:name], drain[:lng], drain[:lat]],
      )
    end
  end

  def load_existing_table
    @conn.execute <<-SQL
      CREATE TEMPORARY TABLE "existing" (
        id varchar,
        location geography(POINT),
        PRIMARY KEY(id)
      );
      CREATE INDEX existing_locations ON existing USING GIST (location);
    SQL

    @conn.execute <<-SQL
      INSERT INTO existing
      SELECT
        city_id AS id,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326) AS location
      FROM things
      WHERE city_domain='#{@city}'
    SQL
  end

  def parse_input
    config = CityHelper.config(@city).data
    columns = config.fetch(:columns)
    data_path = Rails.root.join 'config', 'cities', 'data', config.fetch(:file)
    raise "Missing data file #{data_path}" unless File.exist? data_path

    csv_string = File.open(data_path).read
    drains = CSV.parse(csv_string, headers: true, liberal_parsing: true)

    input = drains.map do |drain|
      id = if columns.key?(:id)
             drain.fetch(columns.fetch(:id))
           else
             SecureRandom.uuid
           end
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

    input.group_by { |i| i[:id] }.map do |id, records|
      puts "Warning: duplicate input ID #{id}. Using first record" if records.size > 1
      records[0]
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
