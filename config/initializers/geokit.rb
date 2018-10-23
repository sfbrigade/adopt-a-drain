# frozen_string_literal: true

if ENV['GOOGLE_GEOCODER_API_KEY']
  Geokit::Geocoders::GoogleGeocoder.api_key = ENV['GOOGLE_GEOCODER_API_KEY']
else
  Rails.logger.warn('$GOOGLE_GEOCODER_API_KEY not set')
end
