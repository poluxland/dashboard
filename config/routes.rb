# config/routes.rb
Rails.application.routes.draw do
  resources :monthly_records
  root "monthly_records#index"

  resources :indicator_readings, only: [ :index, :new, :create, :edit, :update ] do
    collection do
      get  :matrix       # planilla por mes/indicador
      post :matrix_save  # guarda planilla
    end
  end

  resources :people, only: [ :index, :new, :create ]  # para cargar personas rápido
end
