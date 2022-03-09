# frozen_string_literal: true

Rails.application.routes.draw do
  if Rails.env.development? || Rails.env.staging?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  post '/graphql', to: 'graphql#execute'
  # Defines the root path route ("/")
  # root "articles#index"
end
