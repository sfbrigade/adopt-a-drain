# frozen_string_literal: true

class AddDeletedAtToThings < ActiveRecord::Migration[4.2]
  def change
    add_column :things, :deleted_at, :datetime
    add_index :things, :deleted_at
  end
end
