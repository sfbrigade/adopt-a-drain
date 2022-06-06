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
    @current_city ||= CityHelper.city_for_domain(request.host) if respond_to?(:request)
    @current_city
  end

  def self.city_for_domain(domain)
    @@domains[domain]
  end

  def self.config(name)
    @@cities.fetch(name)
  end

  def self.cities
    @@cities
  end

  def self.load!(city_config_dir)
    base = File.join(city_config_dir, 'base.yml')
    @@cities = {}
    @@domains = {}
    Dir[File.join(city_config_dir, '*.yml')].each do |config|
      next if config == base

      city_name = File.basename(config, '.yml')
      city = Schema.load(base, config)
      @@cities[city_name] = city
      city.site.domains.each do |domain|
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
  def self.load_yml(config)
    file_contents = IO.read(config)
    file_contents = ERB.new(file_contents).result
    YAML.safe_load(file_contents)
  end

  def self.load(base, config)
    yml = load_yml(base).deep_merge(load_yml(config))
    result = @@schema.call(yml)
    errors = result.errors(full: true).to_h
    raise "Error validating #{config}:\n#{errors}" unless errors.empty?

    result.to_h.to_dot
  end

  @@schema = Dry::Schema.Params do
    required(:city).hash do
      required(:name).filled(:string)
      required(:type).filled(:string)
      required(:title).filled(:string)
      required(:state).filled(:string)
      required(:center).hash do
        required(:lat).filled(:string)
        required(:lng).filled(:string)
      end
      required(:runoff_destination).filled(:string)
      required(:trash_page_url).filled(:string)
      required(:trash_page_label).filled(:string)
      required(:report_issues).filled(:string)
      required(:logo).filled(:string)
      required(:url).filled(:string)
      required(:facebook).filled(:string)
      required(:instagram).filled(:string)
      required(:twitter).filled(:string)
      required(:linkedin).filled(:string)
    end

    required(:site).hash do
      required(:domains).filled(array[:string])
      required(:main_url).filled(:string)
      required(:logo).filled(:string)
    end

    required(:org).hash do
      required(:email).filled(:string)
      required(:name).filled(:string)
      required(:logo).filled(:string)
      required(:url).filled(:string)
      required(:phone).filled(:string)
    end

    required(:data).hash do
      required(:file).filled(:string)
      required(:columns).hash do
        required(:id).filled(:string)
        required(:lat).filled(:string)
        required(:lng).filled(:string)
        required(:name).filled(array[:string])
      end
    end
  end
end
