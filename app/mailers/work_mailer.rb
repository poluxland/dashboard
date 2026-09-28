class WorkMailer < ApplicationMailer
  class PhotosTooLarge < StandardError; end

  MAX_PHOTO_BYTES = 15.megabytes
  PHOTO_GROUPS = { fotos_antes: "Antes", fotos_despues: "Después", fotos: "Adicionales" }.freeze

  def technical_report(work, recipient:)
    @work = work
    photos = PHOTO_GROUPS.keys.flat_map { |field| work.public_send(field).to_a }
    raise PhotosTooLarge if photos.sum(&:byte_size) > MAX_PHOTO_BYTES

    attachments.inline["impromaq-logo.png"] = {
      mime_type: "image/png",
      content: File.binread(Rails.root.join("app/assets/images/impromaq-logo.png"))
    }

    @photo_groups = PHOTO_GROUPS.map do |field, label|
      names = work.public_send(field).map do |photo|
        filename = "#{field}-#{photo.id}-#{photo.filename}"
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
    }

    mail(to: recipient, subject: "Informe técnico de mantenimiento ##{work.id} · #{work.nombre.presence || 'Impromaq'}")
  end
end
