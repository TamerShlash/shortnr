Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'shortened_uris#new'
  post '/', to: 'shortened_uris#create'

  get '/:key', to: 'shortened_uris#show', constraints: { key: KEY_CONFIG[:regexp] }
end
