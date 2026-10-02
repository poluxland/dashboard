class AddIndicatorEnabledToPeople < ActiveRecord::Migration[8.1]
  def up
    add_column :people, :indicator_enabled, :boolean, default: false, null: false
    execute "UPDATE people SET indicator_enabled = TRUE"
  end

  def down
    remove_column :people, :indicator_enabled
  end
end
