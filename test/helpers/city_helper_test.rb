# frozen_string_literal: true

require 'test_helper'

MAP_CENTER_LAT = '42.4184296'
class CityHelperTest < ActiveSupport::TestCase
  include CityHelper
  include ActionView::Helpers::OutputSafetyHelper

  test 'resolves city from domain' do
    assert_equal 'everett', CityHelper.city_for_domain('localhost')
    assert_equal 'medford', CityHelper.city_for_domain('medford.mysticdrains.org')
    assert_equal 'medford', CityHelper.city_for_domain('medford.localhost')
    assert_nil CityHelper.city_for_domain('unsupported.domain')
  end

  test 'loads' do
    assert_equal MAP_CENTER_LAT, CityHelper.config('medford').city.center.lat
  end

  test 'access current keys' do
    @current_city = 'everett'

    assert_equal '37.774929', c('city.center.lat')
    assert_raise do
      c('city.center.asdfasdf')
    end
    assert_raise do
      c('')
    end
  end
end
