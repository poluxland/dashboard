json.extract! entrega_film, :id, :fecha, :operador_bodega, :rollos_entregados, :observaciones, :created_at, :updated_at
json.url entrega_film_url(entrega_film, format: :json)
