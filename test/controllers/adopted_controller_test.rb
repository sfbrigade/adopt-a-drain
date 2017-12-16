require 'test_helper'

class AdoptedControllerTest < ActionController::TestCase
  setup do
    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = users(:erik)
    @user2 = users(:dan)
    @admin = users(:admin)
    @thing = things(:thing_1)
    @thing2 = things(:thing_2)

    @thing.user_id = @user.id
    @thing2.user_id = @user2.id
    @thing.save
    @thing2.save
  end

  test 'should get index' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, 'correct')

    get :index
    assert_response :success
  end

  test 'should get json' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')

    get :index
    assert_equal 'application/json', @response.content_type
  end

  test 'only admins get access' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, 'correct')

    get :index
    assert_equal 'text/html', @response.content_type # If user were an admin, content_type would be JSON, since that is default
  end


  test 'drain data is correct' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')

    get :index
    random_drain = JSON.parse(@response.body)["drains"].first

    drain = Thing.find_by(city_id: random_drain["city_id"].gsub("N-",""))

    assert_not_nil drain
    assert_equal drain.lat.to_s, random_drain["latitude"]
    assert_equal drain.lng.to_s, random_drain["longitude"]

  end

  test 'page counts' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@admin.email, 'correct')
    
    get :index
    json = JSON.parse(@response.body)
    puts(json)

    assert_equal json["next_page"], 2
    assert_equal json["prev_page"], -1
    assert_equal json["total_pages"], 1
  end
end
