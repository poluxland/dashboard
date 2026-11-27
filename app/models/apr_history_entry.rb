class AprHistoryEntry < ApplicationRecord
  ACTIVITY_DETAIL_LABELS = {
    "type" => "Tipo",
    "sector" => "Sector",
    "place" => "Lugar",
    "modality" => "Modalidad",
    "equipment" => "Equipo",
    "reference" => "Referencia",
    "platform" => "Plataforma",
    "result" => "Resultado documentado"
  }.freeze

  scope :with_listed_activities, -> {
    joins(<<~SQL.squish).select(<<~SQL.squish)
      LEFT JOIN LATERAL unnest(apr_history_entries.activities)
        WITH ORDINALITY AS activity_item(text, position) ON TRUE
    SQL
      apr_history_entries.id, apr_history_entries.date, apr_history_entries.end_date,
      apr_history_entries.plant, apr_history_entries.source_area, apr_history_entries.day_status,
      apr_history_entries.observations, activity_item.text AS listed_activity,
      activity_item.position AS listed_position,
      apr_history_entries.activity_details -> activity_item.position::text AS listed_details
    SQL
  }
end
