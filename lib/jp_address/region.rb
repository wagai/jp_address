# frozen_string_literal: true

module JpAddress
  class Region
    attr_reader :name, :name_en, :prefecture_codes

    REGIONS = [
      { name: "北海道", name_en: "Hokkaido", prefecture_codes: [1] },
      { name: "東北", name_en: "Tohoku", prefecture_codes: [2, 3, 4, 5, 6, 7] },
      { name: "関東", name_en: "Kanto", prefecture_codes: [8, 9, 10, 11, 12, 13, 14] },
      { name: "中部", name_en: "Chubu", prefecture_codes: [15, 16, 17, 18, 19, 20, 21, 22, 23] },
      { name: "近畿", name_en: "Kinki", prefecture_codes: [24, 25, 26, 27, 28, 29, 30] },
      { name: "中国", name_en: "Chugoku", prefecture_codes: [31, 32, 33, 34, 35] },
      { name: "四国", name_en: "Shikoku", prefecture_codes: [36, 37, 38, 39] },
      { name: "九州", name_en: "Kyushu", prefecture_codes: [40, 41, 42, 43, 44, 45, 46, 47] }
    ].freeze

    def initialize(name:, name_en:, prefecture_codes:)
      @name = name
      @name_en = name_en
      @prefecture_codes = prefecture_codes
    end

    def prefectures
      @prefecture_codes.map { |code| Prefecture.find(code) }
    end

    class << self
      def all
        @all ||= REGIONS.map { |data| new(**data) }
      end

      def find(name)
        all.find { |region| region.name == name || region.name_en == name }
      end
    end
  end
end
