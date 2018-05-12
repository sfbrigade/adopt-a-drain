# frozen_string_literal: true

require 'test_helper'

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thing = things(:thing_1)
    @dan = users(:dan)
    @user = users(:erik)
    @admin = users(:admin)
    @thing.user = @dan
    @thing.save!
    stub_request(:get, 'https://maps.google.com/maps/api/geocode/json').
      with(query: {latlng: '42.383339,-71.049226', sensor: 'false'}).
      to_return(body: File.read(File.expand_path('../fixtures/city_hall.json', __dir__)))
  end

  test 'should send a reminder email if admin' do
    sign_in @admin
    num_deliveries = ActionMailer::Base.deliveries.size
    post reminders_url, params: {reminder: {thing_id: @thing.id, to_user_id: @dan.id}, format: :json}
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
    assert_response :success
    email = ActionMailer::Base.deliveries.last
    assert_equal [@dan.email], email.to
    assert_equal 'Remember to clear your adopted drain', email.subject
  end

  test 'should not send a reminder email if not admin' do
    sign_in @user
    num_deliveries = ActionMailer::Base.deliveries.size
    post reminders_url, params: {reminder: {thing_id: @thing.id, to_user_id: @dan.id}, format: :json}
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
  end
end
