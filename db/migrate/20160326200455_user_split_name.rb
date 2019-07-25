# frozen_string_literal: true

class UserSplitName < ActiveRecord::Migration[4.2]
  def up
    # rubocop:disable Rails/BulkChangeTable
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    execute <<-SQL
      UPDATE users SET first_name = split_part(name, ' ', 1);
      UPDATE users SET last_name = ltrim(substring(name, length(first_name) + 1), ' ');
    SQL
    remove_column :users, :name
    # rubocop:enable Rails/BulkChangeTable
  end

  def down
    # rubocop:disable Rails/BulkChangeTable
    add_column :users, :name, :string
    execute <<-SQL
      UPDATE users SET name = concat(first_name, ' ', last_name);
    SQL
    remove_column :users, :first_name
    remove_column :users, :last_name
    # rubocop:enable Rails/BulkChangeTable
  end
end
