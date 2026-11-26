require "csv"

class EquipmentInspectionReport
  KINDS = { "operador" => "Operador", "mantenedor" => "Mantenedor" }.freeze
  STATUSES = EquipmentChecklist::STATUSES.merge(
    MaintenanceChecklist::STATUSES.to_h { |label, (key, color)| [ key, [ label, color ] ] }
  ).merge("sin_estado" => [ "Sin estado operativo", "secondary" ]).freeze
  FINDINGS = %w[grave leve fuera_servicio observaciones].freeze
  CHILE = Time.find_zone!("America/Santiago")
  HISTORICAL_OPERATOR_FIELDS = (18..30).map { |number| :"c#{number}" }.freeze
  UNIQUE_ASSETS = <<~SQL.squish.freeze
    SELECT LOWER(TRIM(code)) AS normalized_code, MIN(id) AS id
    FROM mobile_assets WHERE NULLIF(TRIM(code), '') IS NOT NULL
    GROUP BY LOWER(TRIM(code)) HAVING COUNT(*) = 1
  SQL

  def initialize(filters)
    @filters = filters
  end

  def rows
    scope = all_rows
    scope = scope.where(kind: @filters[:kind]) if KINDS.key?(@filters[:kind])
    if @filters[:asset_id].present?
      asset_id = Integer(@filters[:asset_id].to_s, 10, exception: false)
      scope = asset_id ? scope.where(resolved_asset_id: asset_id) : scope.none
    end
    scope = scope.where(report_plant: @filters[:plant]) if @filters[:plant].present?
    scope = scope.where(report_status: @filters[:status]) if STATUSES.key?(@filters[:status])
    if @filters[:observations] == "1"
      scope = scope.where("report_status IN (?) OR NULLIF(BTRIM(report_comments), '') IS NOT NULL", FINDINGS)
    end

    from = local_midnight(@filters[:from])
    to = local_midnight(@filters[:to], next_day: true)
    scope = scope.where(created_at: from..) if from
    scope = scope.where(created_at: ...to) if to
    scope
  end

  def plant_options
    EquipmentChecklist::PLANTS.keys
  end

  def csv(scope)
    CSV.generate(+"\uFEFF", col_sep: ";") do |file|
      file << [
        "Tipo", "N.º Dashboard", "N.º ERP", "Fecha (Chile)", "Equipo", "Código histórico", "Planta",
        "Responsable", "Horómetro", "Resultado", "Comentarios",
        *EquipmentChecklist::QUESTIONS.values.map { |question| "Operador · #{question}" },
        *HISTORICAL_OPERATOR_FIELDS.map { |field| "Operador · Campo histórico #{field}" },
        *MaintenanceChecklist::QUESTIONS.values.map { |question| "Mantenedor · #{question}" },
        *MaintenanceChecklist::FLUIDS.values,
        "Creado por", "Última modificación por"
      ]
      scope.find_in_batches(cursor: %i[created_at kind id], order: %i[desc asc desc]) do |rows|
        operators = EquipmentChecklist.where(id: rows.select { |row| row.kind == "operador" }.map(&:id)).index_by(&:id)
        maintainers = MaintenanceChecklist.where(id: rows.select { |row| row.kind == "mantenedor" }.map(&:id)).index_by(&:id)
        rows.each do |row|
          operator = row.kind == "operador" ? operators[row.id] : nil
          maintainer = row.kind == "mantenedor" ? maintainers[row.id] : nil
          values = [
            KINDS.fetch(row.kind), row.id, row.erp_id, row.created_at.in_time_zone(CHILE).strftime("%d/%m/%Y %H:%M"),
            row.asset_code, row.legacy_code, EquipmentChecklist::PLANTS.fetch(row.report_plant, row.report_plant),
            row.inspector, row.meter_reading, STATUSES.fetch(row.report_status).first, row.report_comments,
            *EquipmentChecklist::QUESTIONS.keys.map { |field| operator&.[](field) },
            *HISTORICAL_OPERATOR_FIELDS.map { |field| operator&.[](field) },
            *MaintenanceChecklist::QUESTIONS.keys.map { |field| MaintenanceChecklist::ANSWERS.fetch(maintainer[field]) if maintainer },
            *MaintenanceChecklist::FLUIDS.keys.map { |field| maintainer&.[](field) },
            row.created_by_email, row.updated_by_email
          ]
          file << values.map { |value| safe_cell(value) }
        end
      end
    end
  end

  private

  def all_rows
    combined = Arel::Nodes::UnionAll.new(Arel.sql(operator_sql), Arel.sql(maintenance_sql))
    EquipmentChecklist.from(Arel::Nodes::TableAlias.new(combined, EquipmentChecklist.table_name)).readonly
  end

  def operator_sql
    <<~SQL
      SELECT equipment_checklists.id, equipment_checklists.erp_id, equipment_checklists.created_at,
             'operador' AS kind, asset.id AS resolved_asset_id, equipment_checklists.legacy_code,
             COALESCE(NULLIF(asset.code, ''), NULLIF(equipment_checklists.legacy_code, '')) AS asset_code,
             #{plant_code("equipment_checklists.c17")} AS report_plant,
             equipment_checklists.operator AS inspector, equipment_checklists.hour_meter::text AS meter_reading,
             (#{EquipmentChecklist::STATUS_SQL}) AS report_status, equipment_checklists.comments AS report_comments,
             equipment_checklists.created_by_email, equipment_checklists.updated_by_email
      FROM equipment_checklists
      #{asset_join("equipment_checklists")}
    SQL
  end

  def maintenance_sql
    <<~SQL
      SELECT record.id, record.erp_id, record.created_at, 'mantenedor' AS kind,
             asset.id AS resolved_asset_id, record.legacy_code,
             COALESCE(NULLIF(asset.code, ''), NULLIF(record.legacy_code, '')) AS asset_code,
             #{plant_code("asset.plant")} AS report_plant, record.technician AS inspector,
             record.hour_meter AS meter_reading,
             CASE record.operating_status
               WHEN 'Operativo' THEN 'operativo'
               WHEN 'Observaciones' THEN 'observaciones'
               WHEN 'Fuera de servicio' THEN 'fuera_servicio'
               ELSE 'sin_estado'
             END AS report_status, NULL::text AS report_comments, record.created_by_email, record.updated_by_email
      FROM maintenance_checklists AS record
      #{asset_join("record")}
    SQL
  end

  def plant_code(column)
    <<~SQL.squish
      CASE UPPER(TRIM(#{column}))
        WHEN 'LCA' THEN 'LCA' WHEN 'LA CALERA' THEN 'LCA'
        WHEN 'PTM' THEN 'PTM' WHEN 'PUERTO MONTT' THEN 'PTM'
        WHEN 'VTS' THEN 'VTS' WHEN 'VENTANAS' THEN 'VTS'
      END
    SQL
  end

  def asset_join(table)
    <<~SQL
      LEFT JOIN (#{UNIQUE_ASSETS}) AS legacy
        ON #{table}.mobile_asset_id IS NULL AND legacy.normalized_code = LOWER(TRIM(#{table}.legacy_code))
      LEFT JOIN mobile_assets AS asset ON asset.id = COALESCE(#{table}.mobile_asset_id, legacy.id)
    SQL
  end

  def local_midnight(value, next_day: false)
    return if value.blank?

    date = Date.iso8601(value)
    date += 1 if next_day
    CHILE.local(date.year, date.month, date.day)
  rescue ArgumentError
    nil
  end

  def safe_cell(value)
    return value unless value.is_a?(String) && value.match?(/\A[\s\u0000-\u001f]*[=+@-]/)

    "'#{value}"
  end
end
