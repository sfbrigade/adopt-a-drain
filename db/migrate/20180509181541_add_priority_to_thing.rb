# frozen_string_literal: true

class AddPriorityToThing < ActiveRecord::Migration[5.2]
  def change
    add_column :things, :priority, :boolean, default: false, null: false
    change_column :things, :priority, :boolean, null: false
  end
end
