# frozen_string_literal: true

module Basho
  # 地方区分を表すイミュータブルなデータクラス。
  # 北海道、東北、関東、中部、近畿、中国、四国、九州、沖縄の9地方。
  #
  # @!attribute [r] name
  #   @return [String] 地方名（例: "関東"）
  # @!attribute [r] name_en
  #   @return [String] 英語名（例: "Kanto"）
  # @!attribute [r] prefecture_codes
  #   @return [Array<Integer>] 所属する都道府県コードの配列
  Region = ::Data.define(:name, :name_en, :prefecture_codes) do
    # 所属する都道府県の一覧を返す。
    #
    # @return [Array<Prefecture>]
    def prefectures
      prefecture_codes.map { |code| Prefecture.find(code) }
    end

    class << self
      # 全9地方を返す。
      #
      # @return [Array<Region>]
      def all
        @all ||= [
          new(name: "北海道", name_en: "Hokkaido", prefecture_codes: [1]),
          new(name: "東北", name_en: "Tohoku", prefecture_codes: [2, 3, 4, 5, 6, 7]),
          new(name: "関東", name_en: "Kanto", prefecture_codes: [8, 9, 10, 11, 12, 13, 14]),
          new(name: "中部", name_en: "Chubu", prefecture_codes: [15, 16, 17, 18, 19, 20, 21, 22, 23]),
          new(name: "近畿", name_en: "Kinki", prefecture_codes: [24, 25, 26, 27, 28, 29, 30]),
          new(name: "中国", name_en: "Chugoku", prefecture_codes: [31, 32, 33, 34, 35]),
          new(name: "四国", name_en: "Shikoku", prefecture_codes: [36, 37, 38, 39]),
          new(name: "九州", name_en: "Kyushu", prefecture_codes: [40, 41, 42, 43, 44, 45, 46]),
          new(name: "沖縄", name_en: "Okinawa", prefecture_codes: [47])
        ].freeze
      end

      # 日本語名または英語名で地方を検索する。
      #
      # @param name [String] 地方名（例: "関東", "Kanto"）
      # @return [Region, nil]
      def find(name)
        all.find { |region| region.name == name || region.name_en == name }
      end
    end
  end
end
