json.extract! work, :id, :fecha, :planta, :numero_cotizacion, :solicita, :supervisor, :hora_inicio, :hora_termino, :nombre, :seguridad, :descripcion, :personal, :area, :tag, :repuestos, :epp, :hallazgos, :observaciones, :created_at, :updated_at
json.url work_url(work, format: :json)
json.inspections work.selected_inspections do |inspection|
  json.extract! inspection, :id, :template_key, :title
  json.summary inspection.summary
  json.items inspection.items do |item|
    json.extract! item, :id, :position, :question, :answer, :observations
    json.photos item.fotos do |photo|
      json.filename photo.filename.to_s
      json.url rails_blob_url(photo)
    end
  end
end
