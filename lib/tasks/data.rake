require 'rake'

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task download_csv: :environment do
    TYPES_TO_SKIP = ["HEADWALL", "END SECTION"]

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

    drains.each_slice(100) do |group|
      print "."
      group.each { |drain|
        thing_hash = {
          name: drain['type'],
          system_use_code: drain['type'],
          lat: drain['lat'],
          lng: drain['lon'],
        }

        Thing.create(thing_hash)
      }
    end
  end
end
