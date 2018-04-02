# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:erik)
  end

  test 'should redirect to root path' do
    get new_user_session_url
    assert_response :redirect
  end

  test 'should redirect if user is already authenticated' do
    sign_in @user
    get new_user_session_url
    assert_response :redirect
  end

  test 'should authenticate user if password is correct' do
    post user_session_url, params: {user: {email: @user.email, password: 'correct'}, format: :json}
    assert_response :success
  end

  test 'should return error if password is incorrect' do
    post user_session_url, params: {user: {email: @user.email, password: 'incorrect'}, format: :json}
    assert_response 401
  end

  test 'should empty session on sign out' do
    sign_in @user
    get '/'
    assert_not_nil controller.current_user
    delete destroy_user_session_url, params: {format: :json}
    assert_nil controller.current_user
    assert_response :success
  end
end
