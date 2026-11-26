class AddRecordAttribution < ActiveRecord::Migration[8.1]
  TABLES = %i[
    clinker_transfers enfundados entrega_films envasadora_reports equipment_checklists estado_canchas
    estado_equipos indicator_readings maintenance_checklists mantenciones mobile_assets monthly_records
    operation_activities ots overtime_entries overtime_reviews people pmm_bru_visits pmm_materials
    pmm_trucks pmm_yards ptm_events ptm_reports shift_reports soplados task_comments task_items tasks
    tpt_events tpt_imports trabajos work_inspection_items work_inspections works
  ].freeze

  HISTORICAL_CREATORS = {
    author_email: %i[clinker_transfers envasadora_reports overtime_entries ptm_reports task_comments tpt_imports trabajos],
    creator_email: %i[tasks],
    reviewer_email: %i[overtime_reviews],
    signer_email: %i[shift_reports]
  }.freeze

  def up
    TABLES.each do |table|
      change_table table, bulk: true do |columns|
        columns.string :created_by_email
        columns.string :updated_by_email
      end
    end

    HISTORICAL_CREATORS.each do |column, tables|
      tables.each do |table|
        execute <<~SQL
          UPDATE #{table}
          SET created_by_email = LOWER(BTRIM(#{column}))
          WHERE BTRIM(#{column}) ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
        SQL
      end
    end

    execute <<~SQL
      UPDATE tpt_events
      SET created_by_email = tpt_imports.created_by_email
      FROM tpt_imports
      WHERE tpt_events.tpt_import_id = tpt_imports.id AND tpt_imports.created_by_email IS NOT NULL
    SQL
  end

  def down
    TABLES.reverse_each { |table| remove_columns table, :created_by_email, :updated_by_email }
  end
end
