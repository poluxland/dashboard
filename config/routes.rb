# config/routes.rb
Rails.application.routes.draw do
  resources :monthly_records
  root "monthly_records#index"

  resources :indicator_readings, only: [ :index, :new, :create, :edit, :update ] do
    collection do
      get  :matrix
      post :matrix_save
    end
  end

  # habilita CRUD completo
  resources :people   # (o: only: [:index, :new, :create, :edit, :update, :destroy, :show])
end
