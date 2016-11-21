Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  root 'checkouts#index'

  # tabs
  get '/games', to: 'games#index', as: :games
  get '/find', to: 'checkouts#find', as: :find
  get '/admin', to: 'admin#index', as: :admin
  get '/recent', to: 'checkouts#recent', as: :recent

  # to be sprockets
  get '/status', to: 'application#app_status', as: :status

  # checkouts page
  get '/attendee/status', to: 'attendees#status'
  post '/attendee/new', to: 'attendees#new'
  post '/checkout/new', to: 'checkouts#new'
  post '/return', to: 'checkouts#return'

  # admin page
  get '/admin/setup', to: 'admin#setup', as: :setup
  get '/admin/teardown', to: 'admin#teardown', as: :teardown
  get '/admin/events', to: 'admin#events', as: :events
  get '/admin/cull', to: 'admin#cull', as: :cull
  get '/admin/new_game', to: 'admin#new_game', as: :new_game
  get '/admin/metrics/:event', to: 'admin#metrics', as: :metrics
  get '/admin/purge', to: 'admin#purge', as: :purge

  post '/admin/events', to: 'events#create'
  get '/admin/events/edit', to: 'events#edit'
  put '/admin/events/:id', to: 'events#update'
  get '/admin/events/cancel', to: 'events#cancel'

  get '/titles', to: 'admin#titles'
  get '/admin/titles/edit', to: 'titles#edit'
  put '/admin/titles/:id', to: 'titles#update'
  get '/admin/titles/cancel', to: 'titles#cancel'

  get '/publishers', to: 'admin#publishers'

  get '/game/status', to: 'games#status'
  post '/game/new', to: 'games#new'
  get '/game/display', to: 'games#display'

  post '/suggest', to: 'application#suggest_a_title'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
