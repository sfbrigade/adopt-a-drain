# frozen_string_literal: true

require 'test_helper'

MAP_CENTER_LAT = 42.4184296
class CityHelperTest < ActiveSupport::TestCase
  include CityHelper

  test 'loads' do
    assert_equal MAP_CENTER_LAT, CityHelper.config('somerville').map_center.lat
    assert_equal 'default', CityHelper.config('somerville').test_default_field
    assert_raise do
      CityHelper.config('somerville').missing_field
    end
  end

  test 'access current keys' do
    assert_equal MAP_CENTER_LAT, c('map_center.lat')
    assert_raise do
      c('map_center.asdfasdf')
    end
    assert_raise do
      c('')
    end
  end
end
