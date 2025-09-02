class CreateMonthlyRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_records do |t|
      t.date :period
      t.integer :nomina
      t.integer :hh
      t.integer :dp
      t.integer :actp
      t.integer :astp
      t.integer :iap
      t.integer :acreditacion
      t.integer :salud
      t.integer :recepcion
      t.integer :tiempo
      t.integer :soplado
      t.integer :uso_jetin
      t.integer :servicios
      t.integer :despacho

      t.timestamps
    end
  end
end
