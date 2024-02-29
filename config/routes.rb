# frozen_string_literal: true

DiscourseForms::Engine.routes.draw do
  post "/submit/:id" => "forms#create"
  get "/submit/:id" => "forms#show"
  get "/submit" => "forms#index"
  get "/list" => "forms#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseForms::Engine, at: "/forms" }
