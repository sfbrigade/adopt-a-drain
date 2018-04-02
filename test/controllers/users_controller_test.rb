# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:erik)
  end

  test 'should render edit form' do
    sign_in @user
    get edit_user_registration_url
    assert_response :success
    assert_select 'form#edit_form' do
      assert_select '[action=?]', '/users'
      assert_select '[method=?]', 'post'
    end
    assert_select 'input', count: 16
    assert_select 'label', count: 13
    assert_select 'input[name="commit"]' do
      assert_select '[type=?]', 'submit'
      assert_select '[value=?]', 'Update'
    end
    assert_select 'a.btn', 'Back'
  end

  test 'should update user if password is correct' do
    sign_in @user
    assert_not_equal 'New Name', @user.name
    put user_registration_url, params: {user: {first_name: 'New', last_name: 'Name', current_password: 'correct'}}
    @user.reload
    assert_equal 'New Name', @user.name
    assert_response :redirect
    assert_redirected_to controller: 'sidebar', action: 'search'
  end

  test 'should return error if password is incorrect' do
    sign_in @user
    put user_registration_url, params: {user: {name: 'New Name', current_password: 'incorrect'}}
    assert_response :error
  end

  test 'should create user if information is valid' do
    post user_registration_url, params: {user: {email: 'user@example.com', first_name: 'User', last_name: '123', password: 'correct', password_confirmation: 'correct'}}
    assert_response :success
  end

  test 'should return error if information is invalid' do
    post user_registration_url, params: {user: {email: 'user@example.com', first_name: 'User', password: 'correct', password_confirmation: 'incorrect'}}
    assert_response :error
  end
end
