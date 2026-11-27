class AprHistoryEntry < ApplicationRecord
  scope :with_listed_activities, -> {
    joins(<<~SQL.squish).select(<<~SQL.squish)
      LEFT JOIN LATERAL unnest(apr_history_entries.activities)
        WITH ORDINALITY AS activity_item(text, position) ON TRUE
    SQL
      apr_history_entries.id, apr_history_entries.date, apr_history_entries.end_date,
      apr_history_entries.plant, apr_history_entries.day_status,
      activity_item.text AS listed_activity,
      activity_item.position AS listed_position,
      apr_history_entries.activity_details -> activity_item.position::text AS listed_details,
      COALESCE(
        NULLIF(apr_history_entries.activity_details -> activity_item.position::text ->> 'observations', ''),
        CASE WHEN cardinality(apr_history_entries.activities) = 1 THEN apr_history_entries.observations END
      ) AS listed_observations
    SQL
  }

  def activity_observations(position)
    activity_details.dig(position.to_s, "observations").presence || (observations if activities.one? && position == 1)
  end
end
