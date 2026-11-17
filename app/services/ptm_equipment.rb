class PtmEquipment
  GROUPS = {
    "Inicio de turno" => [ "inicio turno", "inicio de turno", "partida de equipos" ],
    "Cierre de turno" => [ "cierre de turno", "termino de turno", "termino turno", "cambio de turno" ],
    "Mantenimiento" => %w[mantenimiento mnatenimiento matenimiento mantenimineto mantencion],
    "Operadores" => %w[operador operadores],
    "Extracción" => %w[extraccion extracion],
    "Rotopacker" => %w[rotopacker rotopakcer],
    "Fifos" => %w[fifo fifos],
    "Confección AST" => [ "ast", "confeccion ast" ],
    "Cambio de energía" => [ "cambio de energia", "cambios de energia" ],
    "Cambio de producto" => [ "cambio de producto", "cambio de proudcto" ],
    "Báscula" => [ "bascula", "bascula de pesaje" ],
    "Bicos" => [ "bicos", "bico 3" ],
    "Silos" => %w[silo silos],
    "Sensores" => %w[sensor sensores],
    "Compresor envasadora" => [ "compresor envasadora", "comprersor" ],
    "Elevador de pallets" => [ "eevador de pallets", "elevador de pallets" ],
    "Grúa horquilla" => [ "grua orquilla", "grua horquilla" ],
    "Limpieza de equipos" => [ "limpieza", "limpieza de equipos" ]
  }.freeze

  def self.normalize(value)
    text = value.to_s.strip.gsub(/\s+/, " ")
    key = I18n.transliterate(text).downcase
    GROUPS.find { |_label, variants| variants.include?(key) }&.first || text.downcase.sub(/\A./, &:upcase)
  end

  def self.options
    (GROUPS.keys + %w[Radimat Paletizadora Enfundadora Rotuladora Colación] + PtmEvent.distinct.pluck(:equipment)).uniq.sort
  end
end
