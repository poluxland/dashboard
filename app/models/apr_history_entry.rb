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
end
