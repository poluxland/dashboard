# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_30_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "enfundados", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "especial_plastificado_completo_doble_films_automatica"
    t.integer "especial_plastificado_completo_doble_films_manual"
    t.integer "especial_plastificado_zuncho_reforzado_automatica"
    t.integer "especial_plastificado_zuncho_reforzado_manual"
    t.integer "especial_plastificados_3_vueltas_automatica"
    t.integer "especial_plastificados_3_vueltas_manual"
    t.integer "especial_plastificados_completo_automatica"
    t.integer "especial_plastificados_completo_manual"
    t.integer "especial_plastificados_lados_automatica"
    t.integer "especial_plastificados_lados_manual"
    t.integer "especial_soluble_plastificados_completo_automatica"
    t.integer "especial_soluble_plastificados_completo_manual"
    t.integer "extra_plastificados_completo_doble_films_automatica"
    t.integer "extra_plastificados_completo_doble_films_manual"
    t.integer "extra_plastificados_completo_doble_films_zuncho_automatica"
    t.integer "extra_plastificados_completo_doble_films_zuncho_manual"
    t.integer "extra_plastificados_lados_automatica"
    t.integer "extra_plastificados_lados_manual"
    t.integer "extra_soluble_plastificados_completo_automatica"
    t.integer "extra_soluble_plastificados_completo_manual"
    t.date "fecha"
    t.integer "numero_pallet_enfundado_automatica"
    t.integer "numero_pallet_enfundado_manual"
    t.integer "numero_rollos_films_cambiados_automatica"
    t.integer "numero_rollos_films_cambiados_manual"
    t.integer "numero_rollos_films_tapa", default: 0, null: false
    t.string "operador"
    t.string "turno"
    t.datetime "updated_at", null: false
  end

  create_table "entrega_films", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "fecha"
    t.text "observaciones"
    t.string "operador_bodega"
    t.integer "rollos_entregados"
    t.datetime "updated_at", null: false
  end

  create_table "envasadora_reports", force: :cascade do |t|
    t.date "date", null: false
    t.string "turno", null: false
    t.string "author_email", null: false
    t.datetime "sent_at"
    t.text "observations"
    t.string "silo19_cement", default: "Extra", null: false
    t.decimal "silo19a", precision: 10, scale: 2, null: false
    t.decimal "silo19b", precision: 10, scale: 2, null: false
    t.string "silo20_cement", default: "S4200", null: false
    t.decimal "silo20a", precision: 10, scale: 2, null: false
    t.decimal "silo20b", precision: 10, scale: 2, null: false
    t.string "silo21_cement", default: "Extra", null: false
    t.decimal "silo21a", precision: 10, scale: 2, null: false
    t.decimal "silo21b", precision: 10, scale: 2, null: false
    t.string "silo22_cement", default: "Ultra", null: false
    t.decimal "silo22a", precision: 10, scale: 2, null: false
    t.decimal "silo22b", precision: 10, scale: 2, null: false
    t.string "silo27_cement", default: "Especial", null: false
    t.decimal "silo27", precision: 10, scale: 2, null: false
    t.string "silo28_cement", default: "Ultra", null: false
    t.decimal "silo28", precision: 10, scale: 2, null: false
    t.decimal "enjuagues_super", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "enjuagues_super4", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_especial", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_especial_soluble_completo", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_especial_lados", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_especial_zunchos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_extra", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_extra_soluble_completo", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "plastificado_extra_zunchos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "especial_sacos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "especial_bigbag", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "especial_granel", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "extra_sacos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "extra_bigbag", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "super_bigbag", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "ultra_bigbag", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "extra_granel", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "super_3300_granel", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "super_4200_granel", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "especialsacos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "especial_sacos_soluble", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "extrsacos", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "extra_sacos_soluble", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagextra", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbag_extra_retiro", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagextra1350", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagextra1", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagespecial", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagsuper", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "bigbagplus", precision: 12, scale: 2, default: "0.0", null: false
    t.string "tolvacalle5"
    t.decimal "otros", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silos3000tolva1"
    t.decimal "ns30001", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silos3000tolva4"
    t.decimal "ns30002", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silos3000tolva5"
    t.decimal "ns30003", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silosbigbag1"
    t.decimal "nbb1", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silosbigbag2"
    t.decimal "nbb2", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silosvento1"
    t.decimal "nvento1", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silovento2"
    t.decimal "nvento2", precision: 12, scale: 2, default: "0.0", null: false
    t.string "silovento3"
    t.decimal "nvento3", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "callesilo28", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "callesplanta1", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "callesilo27", precision: 12, scale: 2, default: "0.0", null: false
    t.string "s28c3op"
    t.string "s28c3cemento"
    t.string "s28c3nota"
    t.string "s28c4op"
    t.string "s28c4cemento"
    t.string "s28c4nota"
    t.string "s28c5op"
    t.string "s28c5cemento"
    t.string "s28c5nota"
    t.string "s27c6op"
    t.string "s27c7cemento"
    t.string "s27c7nota"
    t.string "s30c1op"
    t.string "s30c1cemento"
    t.string "s30c1nota"
    t.string "s30c4op"
    t.string "s30c4cemento"
    t.string "s30c4nota"
    t.string "s30c5op"
    t.string "s30c5cemento"
    t.string "s30c5nota"
    t.decimal "prodhaver", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "prodvento", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "prodbb", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "horas_haver", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "horas_vento", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "horas_bigbag", precision: 12, scale: 2, default: "0.0", null: false
    t.string "comentarios_haver"
    t.string "comentarios_vento"
    t.string "comentarios_bigbag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "turno"], name: "index_envasadora_reports_on_date_and_turno"
  end

  create_table "estado_equipos", force: :cascade do |t|
    t.text "comentarios"
    t.datetime "created_at", null: false
    t.string "equipo"
    t.string "equipo_principal"
    t.integer "estado_capachos"
    t.integer "estado_cinta"
    t.integer "estado_estructura"
    t.integer "estado_filtro"
    t.integer "estado_limpieza"
    t.integer "estado_lubricacion"
    t.integer "estado_motor"
    t.integer "estado_polines"
    t.integer "estado_ruedas"
    t.integer "estado_sistema_aire"
    t.datetime "updated_at", null: false
  end

  create_table "indicator_readings", force: :cascade do |t|
    t.decimal "cc", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "cuasi", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "hh", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "lvs", precision: 5, scale: 2, default: "0.0", null: false
    t.date "period", null: false
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "period"], name: "idx_unique_person_period", unique: true
    t.index ["person_id"], name: "index_indicator_readings_on_person_id"
  end

  create_table "mantenciones", force: :cascade do |t|
    t.text "actividad"
    t.string "area"
    t.string "codigo"
    t.text "comentarios"
    t.datetime "created_at", null: false
    t.decimal "duracion", precision: 8, scale: 2
    t.string "especialidad", default: "Eléctrico", null: false
    t.decimal "estado", precision: 5, scale: 2
    t.date "fecha"
    t.string "numero_ot"
    t.string "planificacion", null: false
    t.integer "semana"
    t.string "source_fingerprint"
    t.string "tipo_mantencion", null: false
    t.datetime "updated_at", null: false
    t.index ["especialidad"], name: "index_mantenciones_on_especialidad"
    t.index ["fecha"], name: "index_mantenciones_on_fecha"
    t.index ["numero_ot"], name: "index_mantenciones_on_numero_ot"
    t.index ["source_fingerprint"], name: "index_mantenciones_on_source_fingerprint", unique: true
    t.check_constraint "planificacion::text = ANY (ARRAY['Plan'::character varying, 'Adicional'::character varying, 'Reprogramado'::character varying]::text[])", name: "mantenciones_planificacion_allowed"
    t.check_constraint "tipo_mantencion::text = ANY (ARRAY['Preventiva'::character varying, 'Correctivo Programado'::character varying, 'Correctivo No programado'::character varying, 'Reprogramar'::character varying]::text[])", name: "mantenciones_tipo_mantencion_allowed"
  end

  create_table "monthly_records", force: :cascade do |t|
    t.integer "acreditacion"
    t.integer "actp"
    t.integer "astp"
    t.datetime "created_at", null: false
    t.integer "despacho"
    t.integer "dp"
    t.integer "hh"
    t.integer "iap"
    t.integer "nomina"
    t.date "period"
    t.integer "recepcion"
    t.integer "salud"
    t.integer "servicios"
    t.integer "soplado"
    t.integer "tiempo"
    t.datetime "updated_at", null: false
    t.integer "uso_jetin"
  end

  create_table "ots", force: :cascade do |t|
    t.string "actividad_semanal"
    t.string "area"
    t.integer "cantidad"
    t.string "causa"
    t.string "cc"
    t.string "cod_rep"
    t.string "codigo"
    t.text "comentarios"
    t.string "contratista"
    t.integer "cotizacion"
    t.datetime "created_at", null: false
    t.integer "duracion_hr"
    t.string "esp"
    t.integer "estado"
    t.integer "frecuencia"
    t.integer "hh"
    t.integer "item"
    t.integer "n_personas"
    t.integer "ot_asignada"
    t.integer "repuestos"
    t.string "responsable"
    t.integer "sem_ejec"
    t.integer "semana"
    t.integer "servicio"
    t.string "tipo_ot"
    t.integer "total"
    t.integer "unitario"
    t.datetime "updated_at", null: false
    t.index ["ot_asignada"], name: "index_ots_on_ot_asignada", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "area"
    t.datetime "created_at", null: false
    t.boolean "indicator_enabled", default: false, null: false
    t.string "name"
    t.string "planta"
    t.boolean "shift_report_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["area"], name: "index_people_on_area"
    t.index ["name"], name: "index_people_on_name", unique: true
  end

  create_table "shift_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "observations"
    t.jsonb "participants", default: [], null: false
    t.datetime "sent_at"
    t.string "shift", null: false
    t.string "signer_email", null: false
    t.string "signer_name", null: false
    t.text "statement", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tpt_events", force: :cascade do |t|
    t.bigint "tpt_import_id", null: false
    t.integer "source_row", null: false
    t.string "impact", null: false
    t.string "production_state", null: false
    t.string "reason", null: false
    t.datetime "started_at", null: false
    t.decimal "duration_seconds", precision: 20, scale: 6, null: false
    t.string "source_fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_fingerprint"], name: "index_tpt_events_on_source_fingerprint", unique: true
    t.index ["started_at"], name: "index_tpt_events_on_started_at"
    t.index ["tpt_import_id"], name: "index_tpt_events_on_tpt_import_id"
  end

  create_table "tpt_imports", force: :cascade do |t|
    t.string "filename", null: false
    t.string "author_email", null: false
    t.integer "imported_count", default: 0, null: false
    t.integer "duplicate_count", default: 0, null: false
    t.integer "summary_count", default: 0, null: false
    t.jsonb "issues", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "works", force: :cascade do |t|
    t.string "area"
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.text "epp"
    t.date "fecha"
    t.text "hallazgos"
    t.time "hora_inicio"
    t.time "hora_termino"
    t.string "nombre"
    t.integer "numero_cotizacion"
    t.text "observaciones"
    t.text "personal"
    t.string "planta"
    t.text "repuestos"
    t.text "seguridad"
    t.string "solicita"
    t.string "supervisor"
    t.string "tag"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "indicator_readings", "people"
  add_foreign_key "tpt_events", "tpt_imports"
end
