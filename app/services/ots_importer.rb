# app/services/ots_importer.rb
require "roo"

class OtsImporter
  RAW_HEADER_MAP = {
    "Semana"            => :semana,
    "Item"              => :item,
    "Área"              => :area,
    "Código"            => :codigo,
    "Actividad Semanal" => :actividad_semanal,
    "ESP."              => :esp,
    "Frecuencia"        => :frecuencia,
    "Cód rep."          => :cod_rep,
    "Cantidad"          => :cantidad,
    "$ unitario"        => :unitario,
    "$ Servicio"        => :servicio,
    "OT asignada"       => :ot_asignada,
    "Cotización"        => :cotizacion,
    "CC"                => :cc,
    "Responsable"       => :responsable,
    "Contratista"       => :contratista,
    "Tipo OT"           => :tipo_ot,
    "Estado"            => :estado,
    "Sem ejec"          => :sem_ejec,
    "N° Personas"       => :n_personas,
    "Duracion [hr]"     => :duracion_hr,
    "HH"                => :hh,
    "CAUSA"             => :causa,
    "Comentarios"       => :comentarios
  }.freeze

  def self.call(file_path)
    xlsx   = Roo::Spreadsheet.open(file_path)
    sheet  = xlsx.sheet(0)

    # Normaliza headers del archivo
    header = sheet.row(1).map { |h| normalize_header(h) }
    # Normaliza el mapa esperado (no como constante)
    header_map = RAW_HEADER_MAP.transform_keys { |k| normalize_header(k) }

    created_or_updated = 0

    ActiveRecord::Base.transaction do
      (2..sheet.last_row).each do |i|
        row_hash = Hash[[ header, sheet.row(i) ].transpose]
        attrs    = map_row(row_hash, header_map)

        # Tipos / normalizaciones
        attrs[:ot_asignada] = normalize_int(attrs[:ot_asignada])
        next if attrs[:ot_asignada].blank?

        attrs[:frecuencia]  = normalize_int(attrs[:frecuencia])
        attrs[:cantidad]    = normalize_int(attrs[:cantidad])
        attrs[:unitario]    = normalize_money(attrs[:unitario])   # "$-" => 0
        attrs[:servicio]    = normalize_money(attrs[:servicio])
        attrs[:cotizacion]  = normalize_int(attrs[:cotizacion])
        attrs[:estado]      = normalize_int(attrs[:estado])
        attrs[:sem_ejec]    = normalize_int(attrs[:sem_ejec])
        attrs[:n_personas]  = normalize_int(attrs[:n_personas])
        attrs[:duracion_hr] = normalize_int(attrs[:duracion_hr])
        attrs[:hh]          = normalize_int(attrs[:hh])

        ot = Ot.find_or_initialize_by(ot_asignada: attrs[:ot_asignada])
        ot.assign_attributes(attrs)
        ot.save!
        created_or_updated += 1
      end
    end

    created_or_updated
  end

  def self.map_row(row_hash, header_map)
    attrs = {}
    header_map.each do |normalized_header, attr|
      attrs[attr] = row_hash[normalized_header]
    end
    attrs
  end

  # ---- Helpers ----
  def self.normalize_header(h)
    h.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
      .gsub(/[[:space:]\u00A0]+/, " ") # colapsa espacios + NBSP
      .strip
  end

  def self.normalize_int(v)
    s = v.to_s.strip
    return nil if s.empty?
  
    # quita espacios
    s = s.gsub(/\s+/, "")
  
    if s.include?(",")
      # Formato CL/ES: miles con punto, decimales con coma
      s = s.split(",").first  # elimina todo después de la coma
      s = s.gsub(".", "")     # quita separadores de miles
    else
      # Formato US: miles con coma, decimales con punto
      s = s.gsub(",", "")     # quita separadores de miles
      s = s.split(".").first  # elimina decimales
    end
  
    # conserva dígitos y posible signo
    s = s.gsub(/[^\d-]/, "")
    s.empty? ? nil : s.to_i
  end
  

  def self.normalize_money(v)
    return 0 if v.to_s.strip == "$-"
    normalize_int(v)
  end
end
