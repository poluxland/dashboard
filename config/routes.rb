# config/routes.rb
Rails.application.routes.draw do
  get "/login", to: "sessions#new", as: :login
  get "/auth/google_oauth2/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :entrega_films
  get "mantenciones/importar", to: "mantencion_imports#new", as: :new_mantencion_import
  post "mantenciones/importar", to: "mantencion_imports#create", as: :mantencion_import
  get "mantenciones/pendientes", to: "mantenciones#index", defaults: { pendientes: "1" }, as: :pendientes_mantenciones
  resources :mantenciones do
    collection do
      get :graficos
    end
  end
  resources :enfundados do
  collection do
    get :reporte
    get :inventario_films
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
