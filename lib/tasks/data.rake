require 'rake'

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task download_csv: :environment do
    puts 'Downloading CSV data...'
    arcgis_path = 'ArcGIS/rest/services/PublicWorks/PublicWorks/MapServer/46/query?f=json&returnGeometry=true&outSR=4326&outFields=FACILITYID,LOCATION,OWNER,STATUS,COMMENT,TYPE&where=TYPE%3D%27COMBO%20INLET%27%20and%20OWNER%3D%27CITY-ROW%27'
    uri = "http://gisweb2.durhamnc.gov/#{arcgis_path}&returnIdsOnly=true"
    print "uri: #{uri}\n"
    json_string = open(uri).read
    ids = JSON.parse(json_string)
    output_csv = File.open("durham_drains.csv", "w")
    output_csv.write("lon,lat,owner,status,type\n")
    ids["objectIds"].each_slice(150).each do |chunk|
      uri = "http://gisweb2.durhamnc.gov/#{arcgis_path}&objectIds=#{chunk.join(',')}"
      print "uri: #{uri}\n"
      json_string = open(uri).read
      data = JSON.parse(json_string)
      data["features"].each do |d|
        output_csv.write("#{d["geometry"]["x"]},#{d["geometry"]["y"]},#{d["attributes"]["OWNER"]},#{d["attributes"]["STATUS"]},#{d["attributes"]["TYPE"]}\n")
      end
    end
    output_csv.close
  end

  task load_drains: :environment do
    puts 'Downloading Drains... ... ...'
    url = 'durham_drains.csv'
    csv_string = open(url).read
    drains = CSV.parse(csv_string, headers: true)
    puts "Downloaded #{drains.size} Drains."

    drains.each do |drain|
      thing_hash = {
        name: drain['type'],
        system_use_code: drain['type'],
        lat: drain['lat'],
        lng: drain['lon'],
      }

      thing = Thing.where(city_id: 'Durham').first_or_initialize
      if thing.new_record?
        puts "Updating thing #{thing_hash[:city_id]}"
      else
        puts "Creating thing #{thing_hash[:city_id]}"
      end

      thing.update_attributes!(thing_hash)
    end
  end
end
