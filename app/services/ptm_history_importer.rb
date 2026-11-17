require "digest"

class PtmHistoryImporter
  DATE_CORRECTIONS = { "1/01/0825" => "2025-08-01", "1/11/0825" => "2025-08-11" }.freeze

  def initialize(rows)
    @rows = rows
  end

  def call(dry_run: false)
    shift = nil
    groups = @rows.group_by do |row|
      shift = row["shift"].presence || shift
      raise "Turno inválido en fila #{row['row']}" unless PtmReport::SHIFTS.key?(shift)
      [ Date.iso8601(DATE_CORRECTIONS.fetch(row.fetch("date"), row.fetch("date"))), shift ]
    end
    summary = { reports: groups.size, events: 0, review: [], imported: 0, existing: 0 }
    PtmReport.transaction do
      groups.each do |(date, turno), rows|
        key = "ptm-initial:#{date}:#{turno}"
        if PtmReport.exists?(source_key: key)
          summary[:existing] += 1
          next
        end
        productions = rows.filter_map { |row| row["production"].to_s.strip.presence&.then { |value| Integer(value) } }
        notes = []
        notes << "Varias producciones: #{productions.join(', ')}. Revisar filas originales." if productions.size > 1
        notes << "Fecha posterior a la carga original (17/11/2026)." if date > Date.new(2026, 11, 17)
        report = PtmReport.new(date: date, shift: turno, production: productions.size == 1 ? productions.first : nil,
          author_email: "importacion-ptm", source_key: key, source_rows: rows)
        rows.each do |row|
          report.ptm_events.build(equipment: PtmEquipment.normalize(row["equipment"].presence || "Sin especificar"),
            original_equipment: row["equipment"], reason: row["reason"], minutes: row["minutes"],
            equipment_state: row["state"], source_row: row["row"])
        end
        notes << "Detenciones superiores a 480 minutos." if report.stopped_minutes > 480
        notes << "Hay detenciones sin minutos informados." if report.ptm_events.any? { |event| event.minutes.nil? }
        report.review_notes = notes.join(" ")
        summary[:events] += rows.size
        summary[:review] << { date: date, shift: turno, notes: notes } if notes.any?
        raise ActiveRecord::RecordInvalid, report unless report.valid?
        report.save! unless dry_run
        summary[:imported] += 1
      end
    end
    summary
  end
end
