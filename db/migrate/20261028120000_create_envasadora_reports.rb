class CreateEnvasadoraReports < ActiveRecord::Migration[8.1]
  def change
    create_table :envasadora_reports do |t|
      t.date :date, null: false
      t.string :turno, null: false
      t.string :author_email, null: false
      t.datetime :sent_at
      t.text :observations
      t.string :silo19_cement, null: false, default: "Extra"
      t.decimal :silo19a, precision: 10, scale: 2, null: false
      t.decimal :silo19b, precision: 10, scale: 2, null: false
      t.string :silo20_cement, null: false, default: "S4200"
      t.decimal :silo20a, precision: 10, scale: 2, null: false
      t.decimal :silo20b, precision: 10, scale: 2, null: false
      t.string :silo21_cement, null: false, default: "Extra"
      t.decimal :silo21a, precision: 10, scale: 2, null: false
      t.decimal :silo21b, precision: 10, scale: 2, null: false
      t.string :silo22_cement, null: false, default: "Ultra"
      t.decimal :silo22a, precision: 10, scale: 2, null: false
      t.decimal :silo22b, precision: 10, scale: 2, null: false
      t.string :silo27_cement, null: false, default: "Especial"
      t.decimal :silo27, precision: 10, scale: 2, null: false
      t.string :silo28_cement, null: false, default: "Ultra"
      t.decimal :silo28, precision: 10, scale: 2, null: false
      t.decimal :enjuagues_super, precision: 12, scale: 2, null: false, default: 0
      t.decimal :enjuagues_super4, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_especial, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_especial_soluble_completo, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_especial_lados, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_especial_zunchos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_extra, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_extra_soluble_completo, precision: 12, scale: 2, null: false, default: 0
      t.decimal :plastificado_extra_zunchos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :especial_sacos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :especial_bigbag, precision: 12, scale: 2, null: false, default: 0
      t.decimal :especial_granel, precision: 12, scale: 2, null: false, default: 0
      t.decimal :extra_sacos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :extra_bigbag, precision: 12, scale: 2, null: false, default: 0
      t.decimal :super_bigbag, precision: 12, scale: 2, null: false, default: 0
      t.decimal :ultra_bigbag, precision: 12, scale: 2, null: false, default: 0
      t.decimal :extra_granel, precision: 12, scale: 2, null: false, default: 0
      t.decimal :super_3300_granel, precision: 12, scale: 2, null: false, default: 0
      t.decimal :super_4200_granel, precision: 12, scale: 2, null: false, default: 0
      t.decimal :especialsacos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :especial_sacos_soluble, precision: 12, scale: 2, null: false, default: 0
      t.decimal :extrsacos, precision: 12, scale: 2, null: false, default: 0
      t.decimal :extra_sacos_soluble, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagextra, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbag_extra_retiro, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagextra1350, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagextra1, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagespecial, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagsuper, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bigbagplus, precision: 12, scale: 2, null: false, default: 0
      t.string :tolvacalle5
      t.decimal :otros, precision: 12, scale: 2, null: false, default: 0
      t.string :silos3000tolva1
      t.decimal :ns30001, precision: 12, scale: 2, null: false, default: 0
      t.string :silos3000tolva4
      t.decimal :ns30002, precision: 12, scale: 2, null: false, default: 0
      t.string :silos3000tolva5
      t.decimal :ns30003, precision: 12, scale: 2, null: false, default: 0
      t.string :silosbigbag1
      t.decimal :nbb1, precision: 12, scale: 2, null: false, default: 0
      t.string :silosbigbag2
      t.decimal :nbb2, precision: 12, scale: 2, null: false, default: 0
      t.string :silosvento1
      t.decimal :nvento1, precision: 12, scale: 2, null: false, default: 0
      t.string :silovento2
      t.decimal :nvento2, precision: 12, scale: 2, null: false, default: 0
      t.string :silovento3
      t.decimal :nvento3, precision: 12, scale: 2, null: false, default: 0
      t.decimal :callesilo28, precision: 12, scale: 2, null: false, default: 0
      t.decimal :callesplanta1, precision: 12, scale: 2, null: false, default: 0
      t.decimal :callesilo27, precision: 12, scale: 2, null: false, default: 0
      t.string :s28c3op
      t.string :s28c3cemento
      t.string :s28c3nota
      t.string :s28c4op
      t.string :s28c4cemento
      t.string :s28c4nota
      t.string :s28c5op
      t.string :s28c5cemento
      t.string :s28c5nota
      t.string :s27c6op
      t.string :s27c7cemento
      t.string :s27c7nota
      t.string :s30c1op
      t.string :s30c1cemento
      t.string :s30c1nota
      t.string :s30c4op
      t.string :s30c4cemento
      t.string :s30c4nota
      t.string :s30c5op
      t.string :s30c5cemento
      t.string :s30c5nota
      t.decimal :prodhaver, precision: 12, scale: 2, null: false, default: 0
      t.decimal :prodvento, precision: 12, scale: 2, null: false, default: 0
      t.decimal :prodbb, precision: 12, scale: 2, null: false, default: 0
      t.decimal :horas_haver, precision: 12, scale: 2, null: false, default: 0
      t.decimal :horas_vento, precision: 12, scale: 2, null: false, default: 0
      t.decimal :horas_bigbag, precision: 12, scale: 2, null: false, default: 0
      t.string :comentarios_haver
      t.string :comentarios_vento
      t.string :comentarios_bigbag
      t.timestamps
    end
    add_index :envasadora_reports, [ :date, :turno ]
  end
end
