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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_182000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clinker_transfers", force: :cascade do |t|
    t.date "date", null: false
    t.decimal "tons", precision: 14, scale: 3, null: false
    t.text "observations"
    t.string "author_email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["date"], name: "index_clinker_transfers_on_date", unique: true
  end

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

  create_table "dashboard_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_dashboard_users_on_email", unique: true
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "entrega_films", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "fecha"
    t.text "observaciones"
    t.string "operador_bodega"
    t.integer "rollos_entregados"
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "envasadora_reports", force: :cascade do |t|
    t.integer "sacos_rotos_haver"
    t.integer "sacos_no_reconocidos_haver"
    t.integer "sacos_descartados_haver"
    t.integer "sacos_rotos_vento"
    t.integer "bigbags_rotos"
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
    t.string "source_filename"
    t.integer "source_row"
    t.string "source_fingerprint"
    t.jsonb "source_data", default: {}, null: false
    t.integer "sacos_no_reconocidos_vento"
    t.integer "sacos_descartados_vento"
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["source_fingerprint"], name: "index_envasadora_reports_on_source_fingerprint", unique: true
    t.index ["date", "turno"], name: "index_envasadora_reports_on_date_and_turno"
  end

  create_table "equipment_checklists", force: :cascade do |t|
    t.bigint "erp_id"
    t.bigint "mobile_asset_id"
    t.string "legacy_code"
    t.string "operator"
    t.integer "hour_meter"
    t.string "c1"
    t.string "c2"
    t.string "c3"
    t.string "c4"
    t.string "c5"
    t.string "c6"
    t.string "c7"
    t.string "c8"
    t.string "c9"
    t.string "c10"
    t.string "c11"
    t.string "c12"
    t.string "c13"
    t.string "c14"
    t.string "c15"
    t.string "c16"
    t.string "c17"
    t.string "c18"
    t.string "c19"
    t.string "c20"
    t.string "c21"
    t.string "c22"
    t.string "c23"
    t.string "c24"
    t.string "c25"
    t.string "c26"
    t.string "c27"
    t.string "c28"
    t.string "c29"
    t.string "c30"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["created_at", "id"], name: "index_equipment_checklists_on_created_at_and_id"
    t.index ["erp_id"], name: "index_equipment_checklists_on_erp_id", unique: true
    t.index ["mobile_asset_id"], name: "index_equipment_checklists_on_mobile_asset_id"
  end

  create_table "estado_canchas", force: :cascade do |t|
    t.bigint "pmm_id"
    t.integer "quilimari"
    t.integer "cachinales"
    t.integer "ñilhue"
    t.integer "caolin"
    t.integer "fierro"
    t.integer "puzolana"
    t.integer "tunga"
    t.integer "ceniza"
    t.integer "yeso"
    t.integer "conchuela"
    t.integer "san_pedro"
    t.integer "clinker_a"
    t.integer "clinker_b"
    t.integer "clinker_importado"
    t.text "observaciones"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["created_at", "id"], name: "index_estado_canchas_on_created_at_and_id"
    t.index ["pmm_id"], name: "index_estado_canchas_on_pmm_id", unique: true
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "haver_daily_deliveries", force: :cascade do |t|
    t.date "scheduled_on", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_on"], name: "index_haver_daily_deliveries_on_scheduled_on", unique: true
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
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["person_id", "period"], name: "idx_unique_person_period", unique: true
    t.index ["person_id"], name: "index_indicator_readings_on_person_id"
  end

  create_table "maintenance_checklists", force: :cascade do |t|
    t.bigint "erp_id"
    t.bigint "mobile_asset_id"
    t.string "legacy_code"
    t.string "technician"
    t.string "operating_status"
    t.string "hour_meter"
    t.boolean "c1"
    t.boolean "c2"
    t.boolean "c3"
    t.boolean "c4"
    t.boolean "c5"
    t.boolean "c6"
    t.boolean "c7"
    t.boolean "c8"
    t.boolean "c9"
    t.boolean "c10"
    t.boolean "c11"
    t.boolean "c12"
    t.boolean "c13"
    t.boolean "c14"
    t.boolean "c15"
    t.boolean "c16"
    t.boolean "c17"
    t.boolean "c18"
    t.boolean "c19"
    t.integer "fuel"
    t.integer "engine_oil"
    t.integer "hydraulic_oil"
    t.integer "transmission_oil"
    t.integer "atf_oil"
    t.integer "nuto_oil"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["created_at", "id"], name: "index_maintenance_checklists_on_created_at_and_id"
    t.index ["erp_id"], name: "index_maintenance_checklists_on_erp_id", unique: true
    t.index ["mobile_asset_id"], name: "index_maintenance_checklists_on_mobile_asset_id"
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
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["especialidad"], name: "index_mantenciones_on_especialidad"
    t.index ["fecha"], name: "index_mantenciones_on_fecha"
    t.index ["numero_ot"], name: "index_mantenciones_on_numero_ot"
    t.index ["source_fingerprint"], name: "index_mantenciones_on_source_fingerprint", unique: true
    t.check_constraint "planificacion::text = ANY (ARRAY['Plan'::character varying, 'Adicional'::character varying, 'Reprogramado'::character varying]::text[])", name: "mantenciones_planificacion_allowed"
    t.check_constraint "tipo_mantencion::text = ANY (ARRAY['Preventiva'::character varying, 'Correctivo Programado'::character varying, 'Correctivo No programado'::character varying, 'Reprogramar'::character varying]::text[])", name: "mantenciones_tipo_mantencion_allowed"
  end

  create_table "mobile_assets", force: :cascade do |t|
    t.bigint "erp_id"
    t.string "code"
    t.string "brand"
    t.string "model"
    t.string "plant"
    t.integer "year"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["erp_id"], name: "index_mobile_assets_on_erp_id", unique: true
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "operation_activities", force: :cascade do |t|
    t.date "fecha", null: false
    t.string "area", null: false
    t.text "actividad", null: false
    t.string "tipo", null: false
    t.decimal "estado", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["fecha"], name: "index_operation_activities_on_fecha"
    t.check_constraint "estado >= 0::numeric AND estado <= 100::numeric", name: "operation_activities_estado_range"
  end

  create_table "operation_weekly_deliveries", force: :cascade do |t|
    t.date "week_start", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["week_start"], name: "index_operation_weekly_deliveries_on_week_start", unique: true
  end

  create_table "operator_checklist_report_deliveries", force: :cascade do |t|
    t.string "plant", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plant", "scheduled_at"], name: "idx_on_plant_scheduled_at_19d6013067", unique: true
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
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["ot_asignada"], name: "index_ots_on_ot_asignada", unique: true
  end

  create_table "overtime_entries", force: :cascade do |t|
    t.bigint "erp_id"
    t.datetime "erp_updated_at"
    t.date "fecha"
    t.string "descripcion"
    t.string "area"
    t.string "personal"
    t.time "inicio"
    t.time "termino"
    t.float "he"
    t.integer "ot"
    t.string "traslado"
    t.string "lugar"
    t.string "mandante"
    t.string "estado"
    t.string "ep"
    t.string "author_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["erp_id"], name: "index_overtime_entries_on_erp_id", unique: true
    t.index ["estado", "mandante", "fecha"], name: "index_overtime_entries_on_estado_and_mandante_and_fecha"
  end

  create_table "overtime_login_codes", force: :cascade do |t|
    t.string "email", null: false
    t.string "challenge", null: false
    t.string "digest", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "issued_at", null: false
    t.datetime "used_at"
    t.index ["email"], name: "index_overtime_login_codes_on_email", unique: true
  end

  create_table "overtime_report_deliveries", force: :cascade do |t|
    t.datetime "scheduled_at", null: false
    t.string "recipient", null: false
    t.datetime "sent_at"
    t.index ["scheduled_at", "recipient"], name: "index_overtime_report_deliveries_on_scheduled_at_and_recipient", unique: true
  end

  create_table "overtime_reviews", force: :cascade do |t|
    t.bigint "overtime_entry_id", null: false
    t.string "reviewer_email", null: false
    t.string "previous_status", null: false
    t.string "status", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["overtime_entry_id"], name: "index_overtime_reviews_on_overtime_entry_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "area"
    t.datetime "created_at", null: false
    t.boolean "indicator_enabled", default: false, null: false
    t.string "name"
    t.string "planta"
    t.boolean "shift_report_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["area"], name: "index_people_on_area"
    t.index ["name"], name: "index_people_on_name", unique: true
  end

  create_table "pmm_bru_visits", force: :cascade do |t|
    t.bigint "pmm_id", null: false
    t.datetime "pmm_updated_at"
    t.date "fecha"
    t.time "ingreso"
    t.time "salida"
    t.string "patente"
    t.string "mmpp"
    t.string "comentarios"
    t.integer "numero"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["fecha"], name: "index_pmm_bru_visits_on_fecha"
    t.index ["pmm_id"], name: "index_pmm_bru_visits_on_pmm_id", unique: true
  end

  create_table "pmm_materials", force: :cascade do |t|
    t.bigint "pmm_id"
    t.datetime "pmm_updated_at"
    t.string "nombre"
    t.string "descripcion"
    t.integer "densidad"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["pmm_id"], name: "index_pmm_materials_on_pmm_id", unique: true
  end

  create_table "pmm_truck_report_deliveries", force: :cascade do |t|
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.index ["scheduled_at"], name: "index_pmm_truck_report_deliveries_on_scheduled_at", unique: true
  end

  create_table "pmm_trucks", force: :cascade do |t|
    t.bigint "pmm_id"
    t.datetime "pmm_updated_at"
    t.bigint "pmm_material_id", null: false
    t.date "fecha"
    t.string "tipo"
    t.time "llegada"
    t.time "llamada"
    t.time "salida"
    t.string "patente"
    t.integer "wait"
    t.string "cause"
    t.text "motive"
    t.integer "number"
    t.string "other"
    t.boolean "finished"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["created_at", "id"], name: "index_pmm_trucks_on_created_at_and_id"
    t.index ["fecha"], name: "index_pmm_trucks_on_fecha"
    t.index ["pmm_id"], name: "index_pmm_trucks_on_pmm_id", unique: true
    t.index ["pmm_material_id", "fecha"], name: "index_pmm_trucks_on_pmm_material_id_and_fecha"
    t.index ["pmm_material_id"], name: "index_pmm_trucks_on_pmm_material_id"
  end

  create_table "pmm_yards", force: :cascade do |t|
    t.bigint "pmm_id"
    t.datetime "pmm_updated_at"
    t.bigint "pmm_material_id", null: false
    t.string "nombre"
    t.string "descripcion"
    t.integer "capacidad"
    t.boolean "operativa"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["pmm_id"], name: "index_pmm_yards_on_pmm_id", unique: true
    t.index ["pmm_material_id"], name: "index_pmm_yards_on_pmm_material_id"
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "soplados", force: :cascade do |t|
    t.bigint "erp_id"
    t.string "supervisor"
    t.datetime "fecha"
    t.float "presion1"
    t.float "presion2"
    t.float "presion3"
    t.float "presion4"
    t.float "presion5"
    t.float "presion6"
    t.float "horno"
    t.float "carbon_horno"
    t.float "carbon_precalcinador"
    t.boolean "jetin"
    t.string "mirillas"
    t.float "so3"
    t.integer "tiempo"
    t.integer "operadores"
    t.text "observaciones"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["erp_id"], name: "index_soplados_on_erp_id", unique: true
    t.index ["fecha", "id"], name: "index_soplados_on_fecha_and_id"
  end

  create_table "task_comments", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.text "body", null: false
    t.string "author_email", null: false
    t.string "author_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["task_id"], name: "index_task_comments_on_task_id"
  end

  create_table "task_items", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.string "title", null: false
    t.date "due_on", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["task_id"], name: "index_task_items_on_task_id"
  end

  create_table "task_notifications", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.string "kind", null: false
    t.string "recipient", null: false
    t.date "due_on"
    t.string "deduplication_key", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deduplication_key"], name: "index_task_notifications_on_deduplication_key", unique: true
    t.index ["task_id"], name: "index_task_notifications_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "category", default: "operations", null: false
    t.string "plant", default: "N/A", null: false
    t.string "title", null: false
    t.text "description"
    t.string "assignee_email", null: false
    t.string "creator_email", null: false
    t.date "due_on"
    t.string "status", default: "pending", null: false
    t.string "priority", default: "normal", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["assignee_email", "status", "due_on"], name: "index_tasks_on_assignee_email_and_status_and_due_on"
    t.check_constraint "category::text = ANY (ARRAY['safety'::character varying, 'people'::character varying, 'operations'::character varying]::text[])", name: "tasks_category_allowed"
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
    t.string "created_by_email"
    t.string "updated_by_email"
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "trabajos", force: :cascade do |t|
    t.bigint "erp_id"
    t.string "author_email"
    t.string "planta"
    t.string "ito"
    t.string "descripcion"
    t.bigint "total", default: 0
    t.date "fecha_termino"
    t.string "avance"
    t.integer "op"
    t.integer "factura"
    t.text "observaciones"
    t.string "centro_costo"
    t.string "supervisor"
    t.text "otros"
    t.text "detalle"
    t.string "i1"
    t.integer "q1"
    t.integer "v1"
    t.string "i2"
    t.integer "q2"
    t.integer "v2"
    t.string "i3"
    t.integer "q3"
    t.integer "v3"
    t.string "i4"
    t.integer "q4"
    t.integer "v4"
    t.string "i5"
    t.integer "q5"
    t.integer "v5"
    t.string "i6"
    t.integer "q6"
    t.integer "v6"
    t.string "i7"
    t.integer "q7"
    t.integer "v7"
    t.string "i8"
    t.integer "q8"
    t.integer "v8"
    t.string "i9"
    t.integer "q9"
    t.integer "v9"
    t.string "i10"
    t.integer "q10"
    t.integer "v10"
    t.string "i11"
    t.integer "q11"
    t.integer "v11"
    t.string "i12"
    t.integer "q12"
    t.integer "v12"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["author_email"], name: "index_trabajos_on_author_email"
    t.index ["avance", "planta", "fecha_termino"], name: "index_trabajos_on_avance_and_planta_and_fecha_termino"
    t.index ["erp_id"], name: "index_trabajos_on_erp_id", unique: true
  end

  create_table "work_inspection_items", force: :cascade do |t|
    t.bigint "work_inspection_id", null: false
    t.integer "position", null: false
    t.text "question", null: false
    t.string "answer"
    t.text "observations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["work_inspection_id", "position"], name: "index_work_inspection_items_on_work_inspection_id_and_position", unique: true
    t.index ["work_inspection_id"], name: "index_work_inspection_items_on_work_inspection_id"
  end

  create_table "work_inspections", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "template_key", null: false
    t.string "title", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["work_id", "template_key"], name: "index_work_inspections_on_work_id_and_template_key", unique: true
    t.index ["work_id"], name: "index_work_inspections_on_work_id"
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
    t.string "created_by_email"
    t.string "updated_by_email"
  end

  create_table "ptm_events", force: :cascade do |t|
    t.bigint "ptm_report_id", null: false
    t.string "equipment", null: false
    t.string "original_equipment"
    t.text "reason"
    t.decimal "minutes", precision: 10, scale: 2
    t.string "equipment_state"
    t.integer "source_row"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["ptm_report_id"], name: "index_ptm_events_on_ptm_report_id"
  end

  create_table "ptm_reports", force: :cascade do |t|
    t.jsonb "history_adjustments", default: {}, null: false
    t.date "date", null: false
    t.string "shift", null: false
    t.integer "production"
    t.string "author_email", null: false
    t.string "source_key"
    t.jsonb "source_rows", default: [], null: false
    t.text "review_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by_email"
    t.string "updated_by_email"
    t.index ["date", "shift"], name: "index_ptm_reports_on_date_and_shift", unique: true
    t.index ["source_key"], name: "index_ptm_reports_on_source_key", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "equipment_checklists", "mobile_assets"
  add_foreign_key "indicator_readings", "people"
  add_foreign_key "maintenance_checklists", "mobile_assets"
  add_foreign_key "tpt_events", "tpt_imports"
  add_foreign_key "overtime_reviews", "overtime_entries"
  add_foreign_key "pmm_trucks", "pmm_materials"
  add_foreign_key "pmm_yards", "pmm_materials"
  add_foreign_key "ptm_events", "ptm_reports"
  add_foreign_key "task_comments", "tasks"
  add_foreign_key "task_items", "tasks"
  add_foreign_key "task_notifications", "tasks"
  add_foreign_key "work_inspection_items", "work_inspections"
  add_foreign_key "work_inspections", "works"
end
