# frozen_string_literal: true

class AddCityToThings < ActiveRecord::Migration[5.2]
  def change
    add_column :things, :city_domain, :string

    add_index(:things, %i[city_id city_domain], unique: true, name: 'things_by_city_id_and_domain')
    remove_index :things, column: :city_id
  end
end
