class CreateEnfundados < ActiveRecord::Migration[8.1]
  def change
    create_table :enfundados do |t|
      t.string :operador
      t.date :fecha
      t.string :turno
      t.integer :numero_pallet_enfundado_manual
      t.integer :numero_pallet_enfundado_automatica
      t.integer :especial_plastificados_lados_manual
      t.integer :especial_plastificados_lados_automatica
      t.integer :especial_plastificados_completo_manual
      t.integer :especial_plastificados_completo_automatica
      t.integer :especial_plastificados_3_vueltas_manual
      t.integer :especial_plastificados_3_vueltas_automatica
      t.integer :especial_plastificado_zuncho_reforzado_manual
      t.integer :especial_plastificado_zuncho_reforzado_automatica
      t.integer :especial_plastificado_completo_doble_films_manual
      t.integer :especial_plastificado_completo_doble_films_automatica
      t.integer :especial_soluble_plastificados_completo_manual
      t.integer :especial_soluble_plastificados_completo_automatica
      t.integer :extra_plastificados_lados_manual
      t.integer :extra_plastificados_lados_automatica
      t.integer :extra_plastificados_completo_doble_films_manual
      t.integer :extra_plastificados_completo_doble_films_automatica
      t.integer :extra_plastificados_completo_doble_films_zuncho_manual
      t.integer :extra_plastificados_completo_doble_films_zuncho_automatica
      t.integer :extra_soluble_plastificados_completo_manual
      t.integer :extra_soluble_plastificados_completo_automatica
      t.integer :numero_rollos_films_cambiados_manual
      t.integer :numero_rollos_films_cambiados_automatica

      t.timestamps
    end
  end
end
