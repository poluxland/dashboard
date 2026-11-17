class PtmHistoryCorrector
  def call
    summary = { capped_shifts: 0, filled_minutes: 0, moved_productions: 0, discarded_productions: 0 }
    PtmReport.transaction do
      PtmReport.where.not(source_key: nil).order(:id).lock.each do |report|
        next if report.history_adjustments["times_v1"]

        events = report.ptm_events.order(:id).to_a
        missing = events.select { |event| event.minutes.nil? }
        originals = events.to_h { |event| [ event.id.to_s, event.minutes&.to_s ] }
        missing.each { |event| event.minutes = 1 }
        total = events.sum { |event| event.minutes.to_d }
        if total > 480
          fixed_ids = missing.map(&:id)
          scalable = events.reject { |event| fixed_ids.include?(event.id) }
          budget = 48_000 - missing.size * 100
          raise "Demasiados eventos sin minutos en turno #{report.id}" if budget.negative?
          sum = scalable.sum { |event| event.minutes.to_d }
          allocations = scalable.map do |event|
            exact = event.minutes.to_d * budget / sum
            [ event, exact.floor, exact - exact.floor ]
          end
          remaining = budget - allocations.sum { |_event, cents, _remainder| cents }
          allocations.sort_by { |event, _cents, remainder| [ -remainder, event.id ] }.first(remaining).each { |allocation| allocation[1] += 1 }
          allocations.each { |event, cents, _remainder| event.minutes = cents.to_d / 100 }
          summary[:capped_shifts] += 1
        end
        summary[:filled_minutes] += missing.size
        events.each(&:save!)
        report.history_adjustments["times_v1"] = { "original_minutes" => originals, "filled_event_ids" => missing.map(&:id), "capped" => total > 480 }
        report.review_notes = report.review_notes.to_s.gsub("Detenciones superiores a 480 minutos.", "").gsub("Hay detenciones sin minutos informados.", "").strip
        report.save!
      end
      correct_productions(summary)
    end
    summary
  end
  private

  def next_shift(date, shift)
    shift == "TT" ? [ date + 1, "TN" ] : [ date, { "TN" => "TM", "TM" => "TT" }.fetch(shift) ]
  end

  def correct_productions(summary)
    originals = PtmReport.where("source_key LIKE ?", "ptm-initial:%").order(:date, :id).lock.to_a
    originals.each do |report|
      values = report.source_rows.filter_map { |row| row["production"].to_s.strip.presence&.then { |value| { "row" => row["row"], "value" => Integer(value) } } }
      next unless values.size > 1
      unless report.history_adjustments["productions_v1"]
        report.history_adjustments["productions_v1"] = { "original_values" => values, "moved" => {} }
        report.production = values.first.fetch("value")
        report.save!
      end
    end
    originals.each do |report|
      report.reload
      audit = report.history_adjustments["productions_v1"]
      next unless audit
      date, shift = report.date, report.shift
      audit["discarded"] ||= {}
      audit.fetch("original_values").drop(1).each do |entry|
        date, shift = next_shift(date, shift)
        next if audit.fetch("moved").key?(entry.fetch("row").to_s) || audit.fetch("discarded").key?(entry.fetch("row").to_s)
        target = PtmReport.find_by(date: date, shift: shift)
        if target && (target.production.present? || target.source_key.blank?)
          audit.fetch("discarded")[entry.fetch("row").to_s] = { "production" => entry.fetch("value"), "occupied_report_id" => target.id, "existing" => target.production }
          summary[:discarded_productions] += 1
          next
        end
        target ||= PtmReport.new(date: date, shift: shift, source_key: "ptm-transfer:#{date}:#{shift}", author_email: "importacion-ptm",
          review_notes: "Producción trasladada: no hay detenciones originales para este turno.")
        target.production = entry.fetch("value")
        target.history_adjustments["incoming_productions"] ||= []
        target.history_adjustments["incoming_productions"] << { "source_id" => report.id, "source_row" => entry.fetch("row"), "production" => entry.fetch("value") }
        target.save!
        audit.fetch("moved")[entry.fetch("row").to_s] = target.id
        summary[:moved_productions] += 1
      end
      report.review_notes = report.review_notes.to_s.gsub(/Varias producciones: .*?Revisar filas originales\./, "").gsub(/Producciones pendientes de traslado: [^.]*\./, "").strip
      report.save!
    end
  end
end
