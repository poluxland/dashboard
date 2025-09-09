class AddPlantaToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :planta, :string
  end
end
