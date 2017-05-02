require 'test_helper'

class AdoptedControllerTest < ActionController::TestCase
  setup do
    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = users(:erik)
  end

  test 'should get index' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, 'correct')

    get :index
    assert_response :success
  end
end
