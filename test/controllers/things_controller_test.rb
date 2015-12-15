require 'test_helper'

class ThingsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  setup do
    stub_request(:get, 'https://maps.google.com/maps/api/geocode/json').
      with(query: {latlng: '42.383339,-71.049226', sensor: 'false'}).
      to_return(body: File.read(File.expand_path('../../fixtures/city_hall.json', __FILE__)))

    @thing = things(:thing_1)
    @user = users(:dan)
  end

  test 'should list drains' do
    get :show, format: 'json', lat: 42.358431, lng: -71.059773
    assert_not_nil assigns :things
    assert_response :success
  end

  test 'should update drain' do
    assert_not_equal 'Birdsill', @thing.name
    put :update, format: 'json', id: @thing.id, thing: {name: 'Birdsill'}
    @thing.reload
    assert_equal 'Birdsill', @thing.name
    assert_not_nil assigns :thing
    assert_response :success
  end

  test 'should update drain and send an adopted confirmation email' do
    sign_in @user
    num_deliveries = ActionMailer::Base.deliveries.size
    put :update, format: 'json', id: @thing.id, thing: {name: 'Drain', user_id: @user.id}
    assert @thing.reload.adopted?
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
    assert_response :success

    email = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], email.to
    assert_equal 'Thanks for adopting a drain, Dan! Here’s important info', email.subject
  end

  test 'should send second confirmation email' do
    sign_in @user
    @user.things = [things(:thing_2)]
    put :update, format: 'json', id: @thing.id, thing: {name: 'Drain', user_id: @user.id}
    assert @thing.reload.adopted?
    assert_response :success

    email = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], email.to
    assert_equal "You're a drain-tastic person, Dan!", email.subject
  end

  test 'should send third confirmation email' do
    sign_in @user
    @user.things = [things(:thing_2), things(:thing_3)]
    put :update, format: 'json', id: @thing.id, thing: {name: 'Drain', user_id: @user.id}
    assert @thing.reload.adopted?
    assert_response :success

    email = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], email.to
    assert_equal 'We really do love you, Dan!', email.subject
  end

  test 'should update drain but not send an adopted confirmation email upon abandonment' do
    sign_in @user
    num_deliveries = ActionMailer::Base.deliveries.size
    put :update, format: 'json', id: @thing.id, thing: {name: 'Another Drain', user_id: nil} # a nil user_id is an abandonment
    assert_not @thing.reload.adopted?
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    assert_response :success
  end
end
