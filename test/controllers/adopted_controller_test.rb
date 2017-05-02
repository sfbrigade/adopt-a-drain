require 'test_helper'

class AdoptedControllerTest < ActionController::TestCase
  setup do
    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = users(:erik)
    @admin = users(:admin)
  end

  test 'should get index' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, 'correct')

    get :index
    assert_response :success
  end

  test 'should get json' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')

    get :index, format: :json
    assert_equal 'application/json', @response.content_type
  end

  test 'should get xml' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')

    get :index, format: :xml
    assert_equal 'application/xml', @response.content_type
  end

  test 'should get csv' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')

    get :index, format: :csv
    assert_equal 'text/csv', @response.content_type
  end

  test 'only admins get access' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, 'correct')

    get :index
    assert_equal 'text/html', @response.content_type # If user were an admin, content_type would be JSON, since that is default
  end
end
