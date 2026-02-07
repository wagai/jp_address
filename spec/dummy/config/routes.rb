# frozen_string_literal: true

Rails.application.routes.draw do
  mount JpAddress::Engine, at: "/jp_address"
end
