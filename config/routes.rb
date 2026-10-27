Rails.application.routes.draw do
  devise_for :admins

  get "admin", to: "dashboard#index", as: :admin_root

  resources :users, except: :show
  resources :products, except: :show
  resource  :site_setting, only: %i[edit update]

  root "home#index"
end
