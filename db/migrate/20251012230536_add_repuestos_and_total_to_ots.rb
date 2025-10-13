class AddRepuestosAndTotalToOts < ActiveRecord::Migration[8.0]
  def change
    add_column :ots, :repuestos, :integer
    add_column :ots, :total, :integer
  end
end
