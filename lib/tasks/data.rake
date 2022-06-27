# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity

# Usage:
# rake data:load_drains cities='all'|'everett cambridge...' [write=true]
# write must be set to true for drains to be updated
# Run locally:
# docker compose run web bundle exec rake data:load_drains cities=all write=true
# or
# heroku rake data:load_drains cities=all write=true

def log(*args)
  print '> '
  args.each { |a| print(a) }
  print "\n"
end

namespace :data do
  task load_drains: :environment do
    cities = ENV.fetch('cities')
    cities = if cities == 'all'
               CityHelper.city_names
             else
               cities.split(' ').map { |c| CityHelper.check(c) }
             end
    dry_run = ENV['write'] != 'true'
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

    log 'Dry Run' if @dry_run
  end

  def load_drains(city)
    @city = city

    log
    log "Loading drains for #{@city}"

    @input = parse_input
    load_input_table
    load_existing_table
    @matches = match_drains
    process_matches
    clean_up
  end

  def process_matches
    log "#{@matches[:conflicts].size} conflicting matches: #{@matches[:conflicts]}"
    log "#{@matches[:new_input_ids].size} new drains"
    log "#{@matches[:updated].size} updated drains"
    log "#{@matches[:removed_existing_ids].size} removed drains: #{@matches[:removed_existing_ids]}"

    apply_changes unless @dry_run
  end

  def apply_changes
    raise "Conflicting matches: #{@matches[:conflicts]}" unless @matches[:conflicts].empty?

    log 'Applying changes...'

    log 'Creating new things...'
    @matches[:new_input_ids].each do |id|
      thing = Thing.new(@input.fetch(id))
      thing.save!(validate: false)
    end

    log 'Updating things...'
    @matches[:updated].each do |d|
      input = @input.fetch(d['input_id']).except(:name)
      input = input.except(:city_id) if @generate_id

      thing = Thing.with_deleted.for_city(@city).where(city_id: d['matched_record_id']).first!
      thing.assign_attributes(input)
      thing.deleted_at = nil
      thing.save! if thing.changed?
    end

    log 'Deleting things...'
    @matches[:removed_existing_ids].each_slice(100) do |ids|
      Thing.for_city(@city).where(city_id: ids).destroy_all
    end
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

  def remove_duplicate_inputs
    matched_input = match_input 'input'
    duplicates = matched_input.filter { |_k, v| v.size > 1 }
    return if duplicates.empty?

    dropped = {}
    kept = {}
    duplicates.each do |input_id, records|
      next if dropped.key?(input_id)

      records.each do |d|
        id = d['matched_record_id']
        if id == input_id
          kept[id] = true
        else
          dropped[id] = true
        end
      end
    end

    log "Warning: Co-located input drains found. Keeping #{kept.keys}, Dropping #{dropped.keys}"

    @conn.execute <<-SQL
      DELETE FROM input where id IN (#{dropped.keys.map { |k| "'#{k}'" }.join(', ')})
    SQL
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

    records.
      group_by { |m| m['input_id'] }.
      map { |k, v| [k, v.filter { |x| !x['matched_record_id'].nil? }] }.
      to_h
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

    @input.each do |_k, drain|
      @conn.raw_connection.exec_prepared(
        statement_id,
        [drain[:city_id], drain[:name], drain[:lng], drain[:lat]],
      )
    end

    remove_duplicate_inputs
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
    @generate_id = !columns.key?(:id)
    data_path = Rails.root.join 'config', 'cities', 'data', config.fetch(:file)
    raise "Missing data file #{data_path}" unless File.exist? data_path

    csv_string = File.open(data_path).read
    drains = CSV.parse(csv_string, headers: true, liberal_parsing: true)

    input = drains.map do |drain|
      id = if @generate_id
             SecureRandom.uuid
           else
             drain.fetch(columns.fetch(:id))
           end
      name = columns.fetch(:name).map { |c| drain.fetch(c) }.join(' ').strip!.presence if columns.key?(:name)
      name ||= 'Storm Drain'
      {
        id: id,
        name: name,
        lat: drain.fetch(columns.fetch(:lat)),
        lng: drain.fetch(columns.fetch(:lng)),
      }
    end

    input = input.group_by { |i| i[:id] }.map do |id, records|
      log "Warning: duplicate input ID #{id} (#{records.size} found). Using first record #{records[0]}" if records.size > 1
      records[0]
    end

    input = input.filter do |record|
      if record[:lat].blank?
        log 'Warning: missing lat', record
        false
      elsif record[:lng].blank?
        log 'Warning: missing lon', record
        false
      else
        true
      end
    end

    input.map do |i|
      [i[:id], {
        name: i[:name],
        lat: i[:lat],
        lng: i[:lng],
        city_domain: @city,
        city_id: i[:id],
      }]
    end.to_h
  end
end
