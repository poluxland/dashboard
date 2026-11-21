class OvertimeBatchReview
  class InvalidReview < StandardError; end

  def self.call(reviewer:, ids:, status:, reason:)
    authorized = OvertimeAccess.staff?(reviewer) || OvertimeAccess.external?(reviewer)
    unless authorized && OvertimeEntry::DECISIONS.include?(status)
      raise InvalidReview, "Selecciona una decisión válida."
    end
    unless ids.is_a?(Array) && ids.size.between?(1, 200) && ids.all? { |id| id.to_s.match?(/\A[1-9]\d{0,17}\z/) }
      raise InvalidReview, "Selecciona entre 1 y 200 registros."
    end

    ids = ids.map(&:to_i).uniq
    reason = reason.to_s.strip
    if reason.size > 1000 || (status == "Rechazada" && reason.blank?)
      raise InvalidReview, "Para rechazar, escribe un motivo de hasta 1.000 caracteres."
    end

    OvertimeEntry.transaction do
      entries = OvertimeAccess.entries_for(reviewer).pending_review.where(id: ids).order(:id).lock.to_a
      unless entries.size == ids.size
        raise InvalidReview, "Algún registro ya fue revisado o está fuera de tu asignación. Actualiza la lista y vuelve a seleccionar."
      end

      entries.each do |entry|
        entry.overtime_reviews.create!(reviewer_email: reviewer, previous_status: entry.estado, status: status, reason: reason.presence)
        entry.update!(estado: status)
      end
      entries.size
    end
  end
end
