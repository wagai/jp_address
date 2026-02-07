# frozen_string_literal: true

module JpAddress
  class City
    attr_reader :code, :prefecture_code, :name, :name_kana

    def initialize(code:, prefecture_code:, name:, name_kana:, capital: false)
      @code = code
      @prefecture_code = prefecture_code
      @name = name
      @name_kana = name_kana
      @capital = capital
    end

    def capital?
      @capital
    end

    def prefecture
      Prefecture.find(@prefecture_code)
    end

    class << self
      def find(code)
        return nil unless code.is_a?(String) && code.length == 6

        prefecture_code = code[0..1].to_i
        where(prefecture_code: prefecture_code).find { |city| city.code == code }
      end

      def where(prefecture_code:)
        Data::Loader.cities(prefecture_code).map { |data| new(**data) }
      end

      def valid_code?(code)
        CodeValidator.valid?(code)
      end
    end
  end
end
