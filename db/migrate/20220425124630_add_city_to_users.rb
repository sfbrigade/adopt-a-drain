# frozen_string_literal: true

class AddCityToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :city_domain, :string

    add_index(:users, %i[email city_domain], unique: true, name: 'users_by_email_and_city_domain')
    remove_index :users, column: :email
  end
end
