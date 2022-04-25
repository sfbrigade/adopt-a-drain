# frozen_string_literal: true

require 'dry/schema'
require 'hash_dot'

module CityHelper
  # View helper for reading strings from the config
  def c(key_chain)
    keys = key_chain.to_s.split('.')
    raise 'Must specify keys' if keys.empty?

    config = CityHelper.config(current_city)
    raw(keys.inject(config) { |h, key| h.fetch(key.to_sym) })
  end

  def current_city
    @current_city ||= CityHelper.city_for_domain(request.domain) if respond_to?(:request)
    @current_city
  end

  def self.city_for_domain(domain)
    @@domains[domain]
  end

  def self.config(name)
    @@cities[name]
  end

  def self.cities
    @@cities
  end

  def self.load!(city_config_dir)
    @@cities = {}
    @@domains = {}
    Dir[File.join(city_config_dir, '*.yml')].each do |config|
      city_name = File.basename(config, '.yml')
      city = Schema.load(config)
      @@cities[city_name] = city
      city.domains.each do |domain|
        @@domains[domain] = city_name
      end
    end
  end

  # Placeholder markup
  def self.p(name)
    "'<b style=\"color: red;\">[#{name}]</b>'"
  end
end

class Schema
  def self.load(config)
    file_contents = IO.read(config)
    file_contents = ERB.new(file_contents).result
    yml = YAML.safe_load(file_contents)
    result = @@schema.call(yml)
    errors = result.errors(full: true).to_h
    raise "Error validating #{config}:\n#{errors}" unless errors.empty?

    result.to_h.to_dot
  end

  @@schema = Dry::Schema.Params do
    required(:map_center).hash do
      required(:lat).filled(:string)
      required(:lng).filled(:string)
    end
    required(:city).hash do
      required(:name).filled(:string)
      required(:type).filled(:string)
    end
    required(:domains).filled(array[:string])
    required(:app_url).filled(:string)
    required(:details).hash do
      required(:destination).filled(:string)
      required(:trash_page_label).filled(:string)
      required(:trash_page_url).filled(:string)
      required(:contact_email).filled(:string)
      required(:contact_name).filled(:string)
      required(:report_issues).filled(:string)
    end
  end
end
