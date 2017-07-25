class AdoptedController < ApplicationController
  before_action :authenticate

  def index
    @things = Thing.where.not(user_id: nil)
    render_types
  end

private

  def render_types
    respond_to do |format|
      format.csv do
        headers['Content-Type'] ||= 'text/csv'
        headers['Content-Disposition'] = 'attachment; filename=\'adopted_drains.csv\''
      end
      format.xml { render xml: format_fields(@things) }
      format.all { render json: format_fields(@things) }
    end
  end

  def format_fields(obj)
    obj.map { |thing| {latitude: thing.lat, longitude: thing.lng, city_id: 'N-' + thing.city_id.to_s} }
  end

  def authenticate
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      user = User.find_by(email: username)
      if user && user.valid_password?(password)
        return true if user.admin?
        render html: '<div> You must be an admin to access this page </div>'.html_safe
      end
    end
  end
end
