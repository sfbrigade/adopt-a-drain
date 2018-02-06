require 'rake'

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task download_csv: :environment do
    puts 'Downloading CSV data...'
    arcgis_path = '/api/records/1.0/download/?dataset=stormwater-drains'\
      '&refine.owner=CITY-ROW&refine.status=EXISTING&refine.task=INLET'\
      '&exclude.type=HEADWALL&exclude.type=END+SECTION'\
      '&format=json'
    uri = "https://opendurham.nc.gov#{arcgis_path}"
    print "uri: #{uri}\n"
    json_string = open(uri).read
    json_data = JSON.parse(json_string)
    output_csv = File.open("durham_drains.csv", "w")
    output_csv.write("lon,lat,owner,watershed,type,form\n")

    json_data.each do |d|
      output_csv.write("#{d["fields"]["geo_point_2d"][1]},#{d["fields"]["geo_point_2d"][0]},#{d["fields"]["owner"]},#{d["fields"]["operationalarea"]},#{d["fields"]["type"]},#{d["fields"]["form"]}\n")
    end

    output_csv.close
  end

  task load_drains: :environment do
    puts 'Loading drains...'
    url = 'durham_drains.csv'
    csv_string = open(url).read
    drains = CSV.parse(csv_string, headers: true)
    puts "#{drains.size} Drains."

    total = 0
    drains.each_slice(1000) do |group|
      updated = 0
      created = 0
      group.each do |drain|
        thing_hash = {
          name: drain['type'],
          system_use_code: drain['type'],
          lat: drain['lat'],
          lng: drain['lon'],
        }

        # Match any existing records, accounting for rounding errors:
        thing = Thing
          .where('round(lat, 10) = ?', BigDecimal(thing_hash[:lat]).round(10))
          .where('round(lng, 10) = ?', BigDecimal(thing_hash[:lng]).round(10))
          .first
        if thing
          thing.assign_attributes(thing_hash)
          if thing.changed?
            updated += 1
          end
        else
          Thing.create(thing_hash)
          created += 1
        end
        
        total += 1
      end

      print "updated/created: #{updated}/#{created} ... #{total}\n"
    end
  end
end
