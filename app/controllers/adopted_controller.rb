class AdoptedController < ApplicationController
  before_filter :authenticate, :admin?

  def index
    render html: "<div> You made it!!! </div> "
  end

  private
    def authenticate
      authenticate_or_request_with_http_basic('Administration') do |username, password|
        user = User.find_by(email: username)
        if user && user.valid_password?(password)
           sign_in :user, user
        end
      end
    end

    def admin?
      if user_signed_in?
        render html: "<div> You must be an admin to access this page </div>".html_safe unless current_user.admin?
      end
    end

end
