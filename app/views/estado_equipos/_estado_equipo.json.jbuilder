json.extract! estado_equipo, :id, :equipo_principal, :equipo, :estado_cinta, :estado_motor, :estado_polines, :estado_ruedas, :estado_capachos, :estado_sistema_aire, :estado_filtro, :estado_estructura, :estado_lubricacion, :estado_limpieza, :comentarios, :created_at, :updated_at
json.url estado_equipo_url(estado_equipo, format: :json)
