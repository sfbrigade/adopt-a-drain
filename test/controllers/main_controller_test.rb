# frozen_string_literal: true

require 'test_helper'

class MainControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:erik)
  end

  test 'should return the home page' do
    get '/'
    assert_response :success
    assert_select 'title', 'Adopt-a-Drain San Francisco'
    assert_select 'button#tagline', 'What does it mean to adopt a drain?'
  end

  test 'should show search form when signed in' do
    sign_in @user
    get '/'
    assert_response :success
    assert_select 'form' do
      assert_select '[action=?]', '/address'
      assert_select '[method=?]', 'get'
    end
    assert_select 'label#city_state_label', 'City'
    assert_select 'select#city_state' do
      assert_select 'option', 'San Francisco, California'
    end
    assert_select 'input#address', true
    assert_select 'input[name="commit"]' do
      assert_select '[type=?]', 'submit'
      assert_select '[value=?]', 'Find drains'
    end
    assert_select 'div#map', true
  end
end
