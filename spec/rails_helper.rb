# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/application"
Rails.application.initialize!

require "rspec/rails"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
