# frozen_string_literal: true

Config.setup do |config|
  config.const_name = 'Settings'
  config.fail_on_missing = true
  config.env_prefix = 'SETTINGS'
end
