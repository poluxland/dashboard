class CreateSoplados < ActiveRecord::Migration[8.1]
  def change
    create_table :soplados do |t|
      t.bigint :erp_id
      t.string :supervisor
      t.datetime :fecha
      t.float :presion1
      t.float :presion2
      t.float :presion3
      t.float :presion4
      t.float :presion5
      t.float :presion6
      t.float :horno
      t.float :carbon_horno
      t.float :carbon_precalcinador
      t.boolean :jetin
      t.string :mirillas
      t.float :so3
      t.integer :tiempo
      t.integer :operadores
      t.text :observaciones
      t.timestamps
      t.index :erp_id, unique: true
      t.index [ :fecha, :id ]
    end
  end
end
