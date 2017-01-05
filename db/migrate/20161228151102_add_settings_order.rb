class AddSettingsOrder < ActiveRecord::Migration
  def change
    add_column :settings, :order, :integer
    set_default_orders
  end

  private
  
  def set_default_orders
    Setting.by_section('ldap').each_with_index do |s, i|
      s.update_attributes(order: i)
    end
  end

end
