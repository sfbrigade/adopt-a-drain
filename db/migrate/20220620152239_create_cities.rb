# frozen_string_literal: true

class CreateCities < ActiveRecord::Migration[5.2]
  def change
    create_table :cities do |t|
      t.string :name, null: false
      t.string :export_recipient_emails, array: true, default: []

      t.timestamp :last_export_time, default: Time.zone.at(0)
      t.integer :last_adoption_count, default: 0
      t.integer :last_user_count, default: 0

      t.timestamps
    end

    add_index :cities, :name, unique: true
  end
end
