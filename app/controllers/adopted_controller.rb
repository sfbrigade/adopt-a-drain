class AdoptedController < ApplicationController
  before_action :authenticate

  # GET /api/v1/drains/adopted
  # Optional params:
  #
  #  page
  def index
    get_adopted_things
    make_cur_page
    make_other_pages
    @results = { next_page: @next_page, prev_page: @prev_page, total_pages: @adopted_things.page(1).total_pages, drains: @things }
    render json: @results
  end

private
  
  def get_adopted_things
    @adopted_things = Thing.adopted
  end
  
  # Determine if the user supplied a valid page number, if not they get first page
  def make_cur_page
    page = ((params[:page].blank?) || (params[:page].to_i == 0)) ? 1 :  params[:page]
    @cur_page = @adopted_things.page(page)
    @things = format_fields(@cur_page)
  end

  # Determine next and previous pages, so the user can navigate if needed
  def make_other_pages
    @next_page = @cur_page.next_page.nil? ? -1 : @cur_page.next_page
    @prev_page = @cur_page.prev_page.nil? ? -1 : @cur_page.prev_page
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
