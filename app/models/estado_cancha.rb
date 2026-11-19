class EstadoCancha < ApplicationRecord
  CHILE = Time.find_zone!("America/Santiago")
  MATERIALS = {
    quilimari: "Quilimari",
    cachinales: "Cachinales",
    ñilhue: "Ñilhue",
    caolin: "Caolín",
    fierro: "Fierro",
    puzolana: "Puzolana",
    tunga: "Tunga",
    ceniza: "Poroso",
    yeso: "Yeso",
    conchuela: "Conchuela",
    san_pedro: "Petcoke",
    clinker_a: "Clínker A",
    clinker_b: "Clínker B",
    clinker_importado: "Clínker importado"
  }.freeze
  FIELDS = [ *MATERIALS.keys, :observaciones ].freeze

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  validates(*MATERIALS.keys, numericality: { only_integer: true }, allow_nil: true)

  def local_timestamp
    created_at.in_time_zone(CHILE)
  end
end
