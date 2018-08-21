# frozen_string_literal: true

class AddSystemUseCodeToThings < ActiveRecord::Migration[4.2]
  def change
    add_column :things, :system_use_code, :string
  end
end
