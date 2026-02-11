# frozen_string_literal: true

require "json"

module Basho
  # 同梱データの読み込みに関する名前空間。
  module Data
    # 同梱JSONデータの遅延読み込みとキャッシュ。
    # 各メソッドは初回呼び出し時にJSONファイルを読み込み、以降はキャッシュを返す。
    #
    # @api private
    class Loader
      # 同梱JSONデータのディレクトリパス
      DATA_DIR = File.expand_path("../../../data", __dir__)

      class << self
        # 全47都道府県データを返す。
        #
        # @return [Array<Hash>]
        def prefectures
          @prefectures ||= load_json("prefectures.json")
        end

        # 指定した都道府県の市区町村データを返す。
        #
        # @param prefecture_code [Integer] 都道府県コード
        # @return [Array<Hash>]
        def cities(prefecture_code)
          cities_cache[prefecture_code] ||= load_json("cities/#{format("%02d", prefecture_code)}.json")
        end

        # 廃止された市区町村データを返す。
        #
        # @return [Array<Hash>]
        def deprecated_cities
          @deprecated_cities ||= load_json("deprecated_cities.json")
        end

        # 廃止コードで1件検索する（ハッシュインデックスによる O(1) ルックアップ）。
        #
        # @param code [String] 6桁自治体コード
        # @return [Hash, nil]
        def deprecated_city(code)
          deprecated_cities_by_code[code]
        end

        # 指定したプレフィックスの郵便番号データを返す。
        #
        # @param prefix [String] 3桁プレフィックス（例: "154"）
        # @return [Array<Hash>]
        def postal_codes(prefix)
          postal_cache[prefix] ||= load_json("postal_codes/#{prefix}.json")
        end

        # 全キャッシュをクリアする。
        #
        # @return [void]
        def reset!
          instance_variables.each { |var| remove_instance_variable(var) }
        end

        private

        def cities_cache
          @cities_cache ||= {}
        end

        def postal_cache
          @postal_cache ||= {}
        end

        def deprecated_cities_by_code
          @deprecated_cities_by_code ||= deprecated_cities.to_h { |c| [c[:code], c] }
        end

        def load_json(relative_path)
          path = File.join(DATA_DIR, relative_path)
          return [] unless path.start_with?("#{DATA_DIR}/") && File.exist?(path)

          JSON.parse(File.read(path), symbolize_names: true)
        end
      end
    end
  end
end
