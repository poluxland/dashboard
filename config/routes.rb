# config/routes.rb
Rails.application.routes.draw do
  resources :entrega_films
  resources :enfundados do
  collection do
    get :reporte
  end
end
  resources :estado_equipos do
  collection do
    get :reporte_equipos
  end
end
  resources :works
# OTs + import
# config/routes.rb
resources :ots do
  collection do
    post :import          # POST /ots/import  -> import_ots_path
    get  :graficos        # GET  /ots/graficos -> graficos_ots_path
    get :compact        # GET  /ots/compact  -> compact_ots_path
    get :backlog
  end
end


  # MonthlyRecords + home
  resources :monthly_records
  root "home#index"

  # IndicatorReadings con acciones de colección
  resources :indicator_readings, only: [ :index, :new, :create, :edit, :update ] do
    collection do
      get  :matrix
      post :matrix_save
    end
  end

  # CRUD completo de personas
  resources :people
end
