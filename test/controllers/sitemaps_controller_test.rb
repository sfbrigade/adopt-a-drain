# frozen_string_literal: true

require 'test_helper'

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test 'should return an XML sitemap' do
    get sitemap_url, params: {format: 'xml'}
    assert_response :success
  end
end
