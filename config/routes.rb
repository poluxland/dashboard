# config/routes.rb
Rails.application.routes.draw do
  resources :monthly_records
  root "monthly_records#index"
end
