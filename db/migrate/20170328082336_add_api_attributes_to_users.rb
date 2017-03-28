class AddApiAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :origin_user_id, :integer
    add_column :users, :api_key, :binary
  end
end
