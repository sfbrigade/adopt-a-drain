# frozen_string_literal: true

require 'open-uri'
require 'csv'

class Thing < ApplicationRecord
  acts_as_paranoid
  extend Forwardable
  include ActiveModel::ForbiddenAttributesProtection

  VALID_DRAIN_TYPES = ['Storm Water Inlet Drain', 'Catch Basin Drain'].freeze

  belongs_to :user
  def_delegators :reverse_geocode, :city, :country, :country_code,
                 :full_address, :state, :street_address, :street_name,
                 :street_number, :zip
  has_many :reminders, dependent: :destroy
  validates :city_id,
            uniqueness: {scope: :city_domain, message: 'ID should be unique per city'},
            allow_nil: true
  validates :lat, presence: true
  validates :lng, presence: true
  validates :name, obscenity: true

  scope :adopted,
        lambda { |city_domain|
          where(city_domain: city_domain).where.not(user_id: nil)
        }

  scope :for_city,
        lambda { |city_domain|
          where(city_domain: city_domain)
        }

  def self.find_closest(lat, lng, limit = 10, current_city = nil)
    query = <<-SQL
      SELECT *, earth_distance(ll_to_earth(lat, lng), ll_to_earth(?, ?)) as distance
      FROM things
      WHERE deleted_at is NULL
      AND city_domain #{current_city.nil? ? ' IS NULL' : " = '#{current_city}'"}
      ORDER BY distance
      LIMIT ?
    SQL
    find_by_sql([query, lat.to_f, lng.to_f, limit.to_i])
  end

  def display_name
    (adopted? ? adopted_name : name) || ''
  end

  def reverse_geocode
    @reverse_geocode ||= Geokit::Geocoders::MultiGeocoder.reverse_geocode([lat, lng])
  end

  def adopted?
    !user.nil?
  end

  def as_json(options = {})
    super({methods: [:display_name]}.merge(options))
  end
end
