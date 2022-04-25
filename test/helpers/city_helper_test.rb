# frozen_string_literal: true

require 'test_helper'

MAP_CENTER_LAT = '42.4184296'
class CityHelperTest < ActiveSupport::TestCase
  include CityHelper
  include ActionView::Helpers::OutputSafetyHelper

  test 'resolves city from domain' do
    assert_equal 'placeholder', CityHelper.city_for_domain('localhost')
    assert_equal 'medford', CityHelper.city_for_domain('medford.mysticdrains.org')
    assert_equal 'medford', CityHelper.city_for_domain('medford.localhost')
    assert_nil CityHelper.city_for_domain('unsupported.domain')
  end

  test 'loads' do
    assert_equal MAP_CENTER_LAT, CityHelper.config('medford').map_center.lat
  end

  test 'access current keys' do
    @current_city = 'placeholder'

    assert_equal '37.774929', c('map_center.lat')
    assert_raise do
      c('map_center.asdfasdf')
    end
    assert_raise do
      c('')
    end
  end
end
