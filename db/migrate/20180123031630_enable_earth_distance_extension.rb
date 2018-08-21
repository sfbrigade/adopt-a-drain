# frozen_string_literal: true

class EnableEarthDistanceExtension < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'cube'
    enable_extension 'earthdistance'
  end
end
