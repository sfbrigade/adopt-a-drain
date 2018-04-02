# frozen_string_literal: true

require 'test_helper'

class SidebarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:erik)
  end

  # required by application.js to get the current user
  test 'search form should include current user id' do
    sign_in @user
    get search_url
    assert_select '#current_user_id[value=?]', @user.id.to_s
  end
end
