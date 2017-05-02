class AdoptedController < ApplicationController
  before_filter :authenticate

  def index
    @things = Thing.where.not(:user_id => !nil)
    render json: @things
  end

  private
    def authenticate
      authenticate_or_request_with_http_basic('Administration') do |username, password|
        user = User.find_by(email: username)
        if user && user.valid_password?(password)
          if user.admin? 
            return true
          else
            render html: "<div> You must be an admin to access this page </div>".html_safe
          end
        end
      end
    end


end
