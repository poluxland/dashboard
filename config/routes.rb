# config/routes.rb
Rails.application.routes.draw do
  post "exportar-tabla", to: "table_exports#create", as: :table_export
  resources :pmm_trucks, path: "camiones", only: %i[index show new create edit update destroy] do
    member do
      get :departure, path: "salida"
      patch :departure, action: :record_departure, path: "salida", as: nil
    end
    collection do
      get :month, path: "mes"
      get :history, path: "historial"
      get :report, path: "reporte"
      get :arrivals, path: "llegadas"
      get :annual, path: "informe"
    end
  end
  get "camiones/catalogos/:kind", to: "pmm_catalogs#index", as: :pmm_catalog
  post "camiones/catalogos/:kind", to: "pmm_catalogs#create"
  get "camiones/catalogos/:kind/nuevo", to: "pmm_catalogs#new", as: :new_pmm_catalog_entry
  get "camiones/catalogos/:kind/:id/editar", to: "pmm_catalogs#edit", as: :edit_pmm_catalog_entry
  patch "camiones/catalogos/:kind/:id", to: "pmm_catalogs#update", as: :pmm_catalog_entry
  delete "camiones/catalogos/:kind/:id", to: "pmm_catalogs#destroy"
  resources :trabajos, only: %i[index show new create edit update]
  get "horas/revision/ingresar", to: "overtime_sessions#new", as: :overtime_login
  post "horas/revision/codigo", to: "overtime_sessions#request_code", as: :request_overtime_code
  post "horas/revision/verificar", to: "overtime_sessions#verify", as: :verify_overtime_code
  delete "horas/revision/salir", to: "overtime_sessions#destroy", as: :overtime_logout
  resources :overtime_entries, path: "horas", only: %i[index new create edit update] do
    patch :review, on: :collection, path: "revision"
  end
  resources :soplados do
    get :graficos, on: :collection
  end
  resources :estado_canchas do
    get :historial, on: :collection
  end
  resources :maintenance_checklists, path: "checklists-mantenedor"
  resources :mobile_assets, path: "equipos-moviles"
  resources :equipment_checklists, path: "checklists-equipos" do
    get :report, on: :collection, path: "informe"
  end
  resources :operation_activities, path: "operaciones-ptm", only: %i[index new create edit update]
  resources :apr_days, path: "registro-actividades/cierres", only: :show do
    post :close, path: "cerrar", on: :member
    post :send_email, path: "correo", on: :member
  end
  resources :apr_activities, path: "registro-actividades", only: %i[index show new create edit update] do
    get :follow_ups, path: "seguimientos", on: :collection
    patch :follow_up, path: "seguimiento", on: :member
  end
  resources :tasks, only: [ :index, :show, :new, :create, :edit, :update ] do
    resources :comments, only: :create, controller: "task_comments"
  end
  get "informes/compartidos/:token", to: "public_work_reports#show", as: :public_work_report
  get "reporte-envasadora/productividad", to: "envasadora_dashboard#index", as: :envasadora_dashboard
  get "informes/haver", to: "haver_dashboard#index", as: :haver_dashboard
  resources :clinker_transfers, path: "traslado-clinker-ptm", only: [ :index, :new, :create, :edit, :update ]
  resources :ptm_reports, path: "envasadora-ptm", only: [ :index, :new, :create, :edit, :update ]
  resources :tpt_imports, path: "ventohaver-tpt", only: [ :index, :create, :show ]
  get "/login", to: "sessions#new", as: :login
  get "/auth/google_oauth2/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :envasadora_reports, path: "reporte-envasadora", only: [ :index, :new, :create, :show, :edit, :update ] do
    post :send_email, on: :member
  end

  resources :shift_reports, only: [ :index, :new, :create, :show ] do
    post :send_email, on: :member
  end

  resources :entrega_films
  get "mantenciones/importar", to: "mantencion_imports#new", as: :new_mantencion_import
  post "mantenciones/importar", to: "mantencion_imports#create", as: :mantencion_import
  get "mantenciones/pendientes", to: "mantenciones#index", defaults: { pendientes: "1" }, as: :pendientes_mantenciones
  get "mantenciones/reprogramado", to: "mantenciones#index", defaults: { planificacion: "Reprogramado" }, as: :reprogramado_mantenciones
  get "mantenciones/adicional", to: "mantenciones#index", defaults: { planificacion: "Adicional" }, as: :adicional_mantenciones
  resources :mantenciones do
    collection do
      get :graficos
      get :desglose
      get :area
      get :descargar, defaults: { format: :xlsx }
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
  resources :works do
    member do
      get :email
      post :send_email
    end
  end
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
