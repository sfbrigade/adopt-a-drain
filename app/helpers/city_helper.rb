# frozen_string_literal: true

module CityHelper
  def c(key_chain)
    keys = key_chain.to_s.split('.')
    raise 'Must specify keys' if keys.empty?

    keys.inject(CityHelper.config('somerville')) { |h, key| h[key] }
  end

  def self.config(name)
    @@cities[name]
  end

  def self.cities
    @@cities
  end

  def self.load!(city_config_dir)
    # TOOD: validate
    default_config = File.join(city_config_dir, 'default.yml')
    raise 'missing default config' unless File.exist?(default_config)

    @@cities = {}
    Dir[File.join(city_config_dir, '*.yml')].each do |config|
      next if File.identical?(config, default_config)

      city_name = File.basename(config, '.yml')
      @@cities[city_name] = Config.load_files(default_config, config)
    end
  end
end
