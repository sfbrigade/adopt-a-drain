require "application_system_test_case"

class AdoptionsTest < ApplicationSystemTestCase
  test "signing up to adopt a drain" do
    visit root_path

    click_on "Register / Sign in"
    fill_in "Email address (private)", with: "user@example.com"
    fill_in "First name", with: "Example"
    fill_in "Last name", with: "User"
    fill_in "Choose a password", with: "password"

    click_on "Sign up"

    click_on "Sign out"
  end
end
