# app/services/ots_importer.rb
require "roo"

class OtsImporter
  # Mapa base: encabezados tal como vienen en el archivo (o esperados)
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

  # Alias útiles (múltiples encabezados posibles -> mismo atributo)
  HEADER_ALIASES = {
    # Actividad puede venir como "Actividad" o "Actividad Semanal"
    "actividad"          => :actividad_semanal,
    "actividad semanal"  => :actividad_semanal,

    # Variantes con/ sin símbolo o mayúsculas
    "$ unitario"         => :unitario,
    "unitario"           => :unitario,
    "$ servicio"         => :servicio,
    "servicio"           => :servicio,

    # Comentarios
    "comentarios"        => :comentarios,
  }.freeze

  def self.call(file_path)
    xlsx  = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    # Normaliza headers del archivo
    header      = sheet.row(1).map { |h| normalize_header(h) }
    # Construye el mapa esperado + alias, todo normalizado
    header_map  = RAW_HEADER_MAP.transform_keys { |k| normalize_header(k) }
    alias_map   = HEADER_ALIASES.transform_keys { |k| normalize_header(k) }
    # ¡Importante! Unimos ambos mapas, pero la resolución de colisiones
    # la haremos en map_row agrupando por atributo.
    merged_map  = header_map.merge(alias_map)

    created_or_updated = 0

    ActiveRecord::Base.transaction do
      (2..sheet.last_row).each do |i|
        # Hash { "header_normalizado" => valor_celda }
        row_hash = Hash[[ header, sheet.row(i) ].transpose]
        # Mapea usando aliases sin sobreescribir con nil
        attrs    = map_row(row_hash, merged_map)

        # --- Normalizaciones y "archivo manda" ---
        attrs[:ot_asignada] = normalize_int(attrs[:ot_asignada])
        next if attrs[:ot_asignada].blank?

        attrs[:semana]       = normalize_int(attrs[:semana])
        attrs[:item]         = normalize_int(attrs[:item])
        attrs[:frecuencia]   = normalize_int(attrs[:frecuencia])
        attrs[:cantidad]     = normalize_int(attrs[:cantidad])
        attrs[:unitario]     = normalize_money(attrs[:unitario])    # "" → nil, "$-" → 0
        attrs[:servicio]     = normalize_money(attrs[:servicio])    # "" → nil, "$-" → 0
        attrs[:cotizacion]   = normalize_int(attrs[:cotizacion])
        attrs[:estado]       = normalize_int(attrs[:estado])
        attrs[:sem_ejec]     = normalize_int(attrs[:sem_ejec])
        attrs[:n_personas]   = normalize_int(attrs[:n_personas])
        attrs[:duracion_hr]  = normalize_int(attrs[:duracion_hr])
        attrs[:hh]           = normalize_int(attrs[:hh])

        # Siempre sobrescribe con lo del archivo (incluye nil)
        ot = Ot.find_or_initialize_by(ot_asignada: attrs[:ot_asignada])
        ot.assign_attributes(attrs)
        ot.save!
        created_or_updated += 1
      end
    end

    created_or_updated
  end

  # Mapea teniendo en cuenta que varios encabezados (alias) pueden apuntar al MISMO atributo.
  # Toma el PRIMER valor NO vacío que aparezca entre los alias presentes en la fila.
  def self.map_row(row_hash, header_map)
    attrs = {}
    # Agrupa: :attr => [encabezado_normalizado1, encabezado_normalizado2, ...]
    grouped = header_map.group_by { |_hdr, attr| attr }
                        .transform_values { |pairs| pairs.map(&:first) }

    grouped.each do |attr, header_keys|
      value = nil
      header_keys.each do |key|
        next unless row_hash.key?(key)
        cell = row_hash[key]
        # Si encontramos un valor no vacío, lo tomamos y dejamos de buscar
        unless cell.nil? || cell.to_s.strip.empty?
          value = cell
          break
        end
        # Si estaba vacío, seguimos probando otros alias
      end
      # Si ninguno trajo valor, queda nil (el archivo manda: sobreescribe con nil)
      attrs[attr] = value
    end

    attrs
  end

  # ---- Helpers ----

  # Normaliza encabezados: quita NBSP/espacios extra, pasa a minúsculas,
  # elimina signos problemáticos, y "desacentúa".
  def self.normalize_header(h)
    s = h.to_s
    s = s.encode("UTF-8", invalid: :replace, undef: :replace)
    s = s.gsub(/[[:space:]\u00A0]+/, " ").strip.downcase
    # Translitera (á->a, ñ->n, etc.)
    begin
      s = s.unicode_normalize(:nfkd).encode("ASCII", replace: "", undef: :replace).force_encoding("UTF-8")
    rescue
      # si falla, seguimos con lo que haya
    end
    s = s.gsub(/[.\$\[\]]/, "") # quita . $ [ ]
    s
  end

  def self.normalize_int(v)
    s = v.to_s.strip
    return nil if s.empty?
    s = s.gsub(/\s+/, "")
    if s.include?(",")
      s = s.split(",").first
      s = s.gsub(".", "")
    else
      s = s.gsub(",", "")
      s = s.split(".").first
    end
    s = s.gsub(/[^\d-]/, "")
    s.empty? ? nil : s.to_i
  end

  def self.normalize_money(v)
    return 0 if v.to_s.strip == "$-"
    normalize_int(v)
  end
end
