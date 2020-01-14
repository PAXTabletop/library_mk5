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
  get '/longest', to: 'checkouts#longest', as: :longest
  get '/loaners', to: 'loaners#index', as: :loaners

  # to be sprockets
  get '/status', to: 'application#app_status', as: :status

  # checkouts page
  get '/attendee/status', to: 'attendees#status'
  post '/attendee/new', to: 'attendees#new'
  post '/checkout/new', to: 'checkouts#new'
  post '/return', to: 'checkouts#return'

  # loaners & groups
  post '/groups', to: 'loaners#create'
  get '/groups/edit', to: 'loaners#edit'
  put '/groups/:id', to: 'loaners#update'
  get '/groups/cancel', to: 'loaners#cancel'
  delete '/groups/:id', to: 'loaners#delete'

  get '/loaners/group/:id', to: 'loaners#group_index', as: :group
  post '/loan', to: 'loaners#new'

  get '/groups/deleted', to: 'loaners#groups_deleted', as: :groups_deleted
  put '/groups/restore/:id', to: 'loaners#restore'

  # admin page
  get '/admin/setup', to: 'admin#setup', as: :setup
  get '/admin/teardown', to: 'admin#teardown', as: :teardown
  get '/admin/events', to: 'admin#events', as: :events
  get '/admin/cull', to: 'admin#cull', as: :cull
  get '/admin/new_game', to: 'admin#new_game', as: :new_game
  get '/admin/metrics/:event', to: 'admin#metrics', as: :metrics
  get '/admin/purge', to: 'admin#purge', as: :purge
  get '/admin/missing', to: 'admin#missing', as: :missing
  get '/admin/storage', to: 'admin#storage', as: :storage
  get '/admin/added/:event', to: 'admin#added_games', as: :added
  get '/admin/culled/:event', to: 'admin#culled_games', as: :culled

  put '/setup/tag', to: 'admin#setup_tag', as: :setup_tag
  put '/setup/reset', to: 'admin#reset_setup', as: :reset_setup

  post '/admin/events', to: 'events#create'
  get '/admin/events/edit', to: 'events#edit'
  put '/admin/events/:id', to: 'events#update'
  get '/admin/events/cancel', to: 'events#cancel'

  get '/titles', to: 'admin#titles'
  get '/admin/titles/edit', to: 'titles#edit'
  put '/admin/titles/:id', to: 'titles#update'
  get '/admin/titles/cancel', to: 'titles#cancel'

  get '/publishers', to: 'admin#publishers'
  get '/admin/publishers/edit', to: 'publishers#edit'
  put '/admin/publishers/:id', to: 'publishers#update'
  get '/admin/publishers/cancel', to: 'publishers#cancel'

  get '/tournament', to: 'admin#tournament_games'
  post '/admin/tournament', to: 'tournament_games#create'
  get '/admin/tournament/edit', to: 'tournament_games#edit'
  put '/admin/tournament/:id', to: 'tournament_games#update'
  get '/admin/tournament/cancel', to: 'tournament_games#cancel'
  delete '/admin/tournament/:id', to: 'tournament_games#delete'

  get '/tournament/recently_deleted', to: 'tournament_games#recently_deleted'
  put '/admin/tournament/restore/:id', to: 'tournament_games#restore'

  get '/about', to: 'admin#about'

  get '/reports', to: 'admin#reports'
  get '/games/csv', to: 'games#csv'
  get '/titles/csv', to: 'titles#csv'
  get '/checkouts/csv', to: 'checkouts#csv'
  get '/storage/csv', to: 'admin#csv'

  get '/admin/backup', to: 'admin#backup', as: :backup
  post '/backup', to: 'backup#initiate'

  get '/game/status', to: 'games#status'
  post '/game/new', to: 'games#new'
  get '/game/display', to: 'games#display'

  get '/suggestions/:event', to: 'admin#suggestions', as: :suggestions
  post '/suggest', to: 'application#suggest_a_title'

  get '/admin/stats', to: 'admin#stats'

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
