require 'rake'

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task download_csv: :environment do
    puts 'Downloading CSV data...'
    uri = 'http://gisweb2.durhamnc.gov/ArcGIS/rest/services/PublicWorks/PublicWorks/MapServer/46/query?f=json&out&geometry=%7B%22ymax%22:921388.0377604166,%22xmax%22:2228921.275173611,%22ymin%22:750608.9622395834,%22xmin%22:1874322.724826389%7D&returnGeometry=true&outSR=4326&outFields=FACILITYID,LOCATION,OWNER,STATUS,COMMENT,TYPE&returnIdsOnly=true&where=TYPE%3D%27COMBO%20INLET%27'
    json_string = open(uri).read
    ids = JSON.parse(json_string)
    output_csv = File.open("durham_drains.csv", "w")
    output_csv.write("lon,lat,owner,status,type\n")
    ids["objectIds"].each_slice(100).each do |chunk|
      uri = "http://gisweb2.durhamnc.gov/ArcGIS/rest/services/PublicWorks/PublicWorks/MapServer/46/query?f=json&out&geometry=%7B%22ymax%22:921388.0377604166,%22xmax%22:2228921.275173611,%22ymin%22:750608.9622395834,%22xmin%22:1874322.724826389%7D&returnGeometry=true&outSR=4326&outFields=FACILITYID,LOCATION,OWNER,STATUS,COMMENT,TYPE&where=TYPE%3D%27COMBO%20INLET%27&objectIds=#{chunk.join(',')}"
      print "uri: #{uri}\n"
      sleep 1
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
      # lat,lon,owner,status,type
      # next unless ['Storm Water Inlet Drain', 'Catch Basin Drain'].include?(drain['type'])

      lat = drain['lat']
      lng = drain['lon']

      thing_hash = {
        name: drain['type'],
        system_use_code: drain['type'],
        lat: lat,
        lng: lng,
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
