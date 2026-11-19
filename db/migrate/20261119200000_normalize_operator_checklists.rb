class NormalizeOperatorChecklists < ActiveRecord::Migration[8.0]
  def up
    fields = (1..16).map { |number| "c#{number}" }
    answers = "ARRAY[#{fields.join(', ')}]"

    execute <<~SQL
      DELETE FROM equipment_checklists
      WHERE erp_id IN (1, 389, 390, 392)
        AND NOT COALESCE('No(grave)' = ANY(#{answers}) OR 'No(leve)' = ANY(#{answers}) OR 'No' = ANY(#{answers}), false)
        AND ('' = ANY(#{answers}) OR array_position(#{answers}, NULL) IS NOT NULL)
    SQL
    execute <<~SQL
      UPDATE equipment_checklists
      SET #{fields.map { |field| "#{field} = CASE WHEN #{field} = 'No' THEN 'No(leve)' ELSE #{field} END" }.join(', ')}
      WHERE 'No' = ANY(#{answers})
    SQL
    execute <<~SQL
      WITH unique_codes AS (
        SELECT LOWER(TRIM(code)) AS code, MIN(id) AS id
        FROM mobile_assets
        WHERE NULLIF(TRIM(code), '') IS NOT NULL
        GROUP BY LOWER(TRIM(code))
        HAVING COUNT(*) = 1
      ), normalized AS (
        SELECT checklist.id, CASE UPPER(TRIM(asset.plant))
          WHEN 'LCA' THEN 'LCA' WHEN 'LA CALERA' THEN 'LCA'
          WHEN 'PTM' THEN 'PTM' WHEN 'PUERTO MONTT' THEN 'PTM'
          WHEN 'VTS' THEN 'VTS' WHEN 'VENTANAS' THEN 'VTS'
        END AS plant
        FROM equipment_checklists AS checklist
        LEFT JOIN unique_codes AS legacy
          ON checklist.mobile_asset_id IS NULL AND legacy.code = LOWER(TRIM(checklist.legacy_code))
        LEFT JOIN mobile_assets AS asset ON asset.id = COALESCE(checklist.mobile_asset_id, legacy.id)
        WHERE checklist.c17 IS NULL OR checklist.c17 NOT IN ('LCA', 'PTM', 'VTS')
      )
      UPDATE equipment_checklists AS checklist SET c17 = normalized.plant
      FROM normalized WHERE normalized.id = checklist.id AND checklist.c17 IS DISTINCT FROM normalized.plant
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
