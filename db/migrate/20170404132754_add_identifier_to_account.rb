class AddIdentifierToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :identifier, :string
  end
end
