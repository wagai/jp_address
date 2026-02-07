# frozen_string_literal: true

require "json"

module JpAddress
  module Data
    class Loader
      DATA_DIR = File.expand_path("../../../data", __dir__)

      class << self
        def prefectures
          @prefectures ||= load_json("prefectures.json")
        end

        def cities(prefecture_code)
          cache_key = :"@cities_#{prefecture_code}"
          return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)

          file = format("%02d.json", prefecture_code)
          data = load_json("cities/#{file}")
          instance_variable_set(cache_key, data)
        end

        def postal_codes(prefix)
          cache_key = :"@postal_#{prefix}"
          return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)

          data = load_json("postal_codes/#{prefix}.json")
          instance_variable_set(cache_key, data)
        end

        def reset!
          instance_variables.each { |var| remove_instance_variable(var) }
        end

        private

        def load_json(relative_path)
          path = File.join(DATA_DIR, relative_path)
          return [] unless File.exist?(path)

          JSON.parse(File.read(path), symbolize_names: true)
        end
      end
    end
  end
end
