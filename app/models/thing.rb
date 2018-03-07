class Thing < ActiveRecord::Base
  extend Forwardable
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :user
  def_delegators :reverse_geocode, :city, :country, :country_code,
                 :full_address, :state, :street_address, :street_name,
                 :street_number, :zip
  has_many :reminders
  validates :city_id, uniqueness: true, allow_nil: true
  validates :lat, presence: true
  validates :lng, presence: true
  validates :name, obscenity: true

  def self.find_closest(lat, lng, radius_miles)
    # Great circle calculation - distance between lat/long.
    query = <<-SQL
      SELECT * FROM things
			WHERE (3959 * ACOS(COS(RADIANS(?)) * COS(RADIANS(lat)) * COS(RADIANS(lng) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(lat)))) < ?
      SQL
    find_by_sql([query, lat.to_f, lng.to_f, lat.to_f, radius_miles.to_f])
  end

  def reverse_geocode
    @reverse_geocode ||= Geokit::Geocoders::MultiGeocoder.reverse_geocode([lat, lng])
  end

  def adopted?
    !user.nil?
  end

  # Link to more details about type of Thing
  #
  # Currently hardcoding since we only have one special case, but we should
  # move this into the database if we add an additional
  def detail_link
    return 'http://sfwater.org/index.aspx?page=399' if system_use_code == 'MS4'

    nil
  end
end
