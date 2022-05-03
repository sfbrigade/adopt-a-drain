# frozen_string_literal: true

class ChangeCityIdToString < ActiveRecord::Migration[5.2]
  def change
    change_column :things, :city_id, :string
  end
end
