class AddOtAsignadaToOts < ActiveRecord::Migration[8.0]
  def change
    add_column :ots, :ot_asignada, :integer
    add_index  :ots, :ot_asignada, unique: true
  end
end
