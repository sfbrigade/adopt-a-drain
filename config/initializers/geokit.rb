# frozen_string_literal: true

Geokit::Geocoders::GoogleGeocoder.api_key = ENV['GOOGLE_GEOCODER_API_KEY'] || Rails.logger.warn('$GOOGLE_GEOCODER_API_KEY not set')
