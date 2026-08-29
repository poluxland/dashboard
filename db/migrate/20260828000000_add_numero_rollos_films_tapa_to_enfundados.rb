class AddNumeroRollosFilmsTapaToEnfundados < ActiveRecord::Migration[8.1]
  def change
    add_column :enfundados, :numero_rollos_films_tapa, :integer, null: false, default: 0
  end
end
