# frozen_string_literal: true

Basho::Engine.routes.draw do
  get "postal_codes/lookup", to: "postal_codes#lookup", as: :postal_code_lookup
end
