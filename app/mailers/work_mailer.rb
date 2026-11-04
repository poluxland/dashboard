class WorkMailer < ApplicationMailer
  TEAM_RECIPIENTS = %w[jose.jerez@msindustrial.cl julio.alvear@msindustrial.cl fernando.gonzalez@msindustrial.cl].freeze
  class PhotosTooLarge < StandardError; end

  MAX_PHOTO_BYTES = 15.megabytes
  PHOTO_GROUPS = { fotos_antes: "Antes", fotos_despues: "Después", fotos: "Adicionales" }.freeze

  def technical_report(work, recipient:)
    @work = work
    @report_url = public_work_report_url(token: work.report_token)
    inspection_groups = work.selected_inspections.flat_map do |inspection|
      inspection.items.map { |item| [ "#{inspection.title} · #{item.question}", item.fotos.to_a ] }
    end
    groups = PHOTO_GROUPS.map { |field, label| [ label, work.public_send(field).to_a ] } + inspection_groups.reject { |_, photos| photos.empty? }
    photos = groups.flat_map(&:last)
    raise PhotosTooLarge if photos.sum(&:byte_size) > MAX_PHOTO_BYTES

    attachments.inline["impromaq-logo.png"] = {
      mime_type: "image/png",
      content: File.binread(Rails.root.join("app/assets/images/impromaq-logo.png"))
    }

    @photo_groups = groups.each_with_index.map do |(label, group_photos), index|
      names = group_photos.map do |photo|
        filename = "#{index}-#{photo.id}-#{photo.filename}"
        attachments.inline[filename] = { mime_type: photo.content_type, content: photo.download }
        filename
      end
      [ label, names ]
    end
    @details = {
      "Fecha" => work.fecha&.strftime("%d-%m-%Y"), "Planta" => work.planta,
      "Área" => work.area, "Tag" => work.tag, "N° cotización" => work.numero_cotizacion,
      "Solicita" => work.solicita, "Supervisor" => work.supervisor,
      "Hora inicio" => work.hora_inicio&.strftime("%H:%M"),
      "Hora término" => work.hora_termino&.strftime("%H:%M"),
      "Trabajo realizado" => work.descripcion, "Repuestos" => work.repuestos,
      "EPP" => work.epp, "Hallazgos" => work.hallazgos,
      "Observaciones" => work.observaciones, "Seguridad y medio ambiente" => work.seguridad,
      "Personal" => work.personal
    }.compact_blank

    mail(to: recipient, subject: "Informe técnico de mantenimiento ##{work.id} · #{work.nombre.presence || 'Impromaq'}")
  end
end
