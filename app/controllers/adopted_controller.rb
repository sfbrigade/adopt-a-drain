class AdoptedController < ApplicationController
  before_action :authenticate
  before_action :make_cur_page, :make_other_pages, only: [:index]

  # GET /api/v1/drains/adopted
  # Optional params:
  #
  #  format=[json|xml|csv]
  #  page
  def index
    @results = {next_page: @next_page, prev_page: @prev_page, drains: @things}
    render_types
  end

private

  # Determine if the user supplied a valid page number, if not they get first page
  def make_cur_page
    page = params[:page].blank? ? 2 : params[:page]
    @cur_page = Thing.where.not(user_id: nil).page(page)
    @things = format_fields(@cur_page)
  end

  # Determine next and previous pages, so the user can navigate if needed
  def make_other_pages
    @next_page = @cur_page.next_page.nil? ? 0 : @cur_page.next_page
    @prev_page = @cur_page.prev_page.nil? ? 0 : @cur_page.prev_page
  end

  def render_types
    respond_to do |format|
      format.csv do
        headers['Content-Type'] ||= 'text/csv'
        headers['Content-Disposition'] = 'attachment; filename=\'adopted_drains.csv\''

        # Assuming that a CSV was requested in order to retrieve all results at once
        @allthings = Thing.where.not(user_id: nil)
      end
      format.xml { render xml: @results }
      format.all { render json: @results }
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
