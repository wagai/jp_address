# frozen_string_literal: true

module Basho
  # 郵便番号を表すイミュータブルなデータクラス。
  # 常にJSONファイルから読み込む（DBバックエンド対象外）。
  #
  # @!attribute [r] code
  #   @return [String] 7桁郵便番号（ハイフンなし、例: "1540011"）
  # @!attribute [r] prefecture_code
  #   @return [Integer] 都道府県コード（1〜47）
  # @!attribute [r] city_name
  #   @return [String] 市区町村名（例: "世田谷区"）
  # @!attribute [r] town
  #   @return [String] 町域名（例: "上馬"）
  PostalCode = ::Data.define(:code, :prefecture_code, :city_name, :town) do
    # ハイフン付きの郵便番号を返す。
    #
    # @return [String] 例: "154-0011"
    def formatted_code
      "#{code[0..2]}-#{code[3..]}"
    end

    # 都道府県名を返す。
    #
    # @return [String, nil] 例: "東京都"
    def prefecture_name
      prefecture&.name
    end

    # 所属する都道府県を返す。
    #
    # @return [Prefecture, DB::Prefecture, nil]
    def prefecture
      Prefecture.find(prefecture_code)
    end

    class << self
      # 郵便番号で検索する。ハイフン有無どちらも可。
      #
      # @param code [String] 郵便番号（例: "154-0011", "1540011"）
      # @return [PostalCode, nil]
      def find(code)
        where(code: code).first
      end

      # 郵便番号で検索し、配列で返す。共有郵便番号の場合は複数件。
      #
      # @param code [String] 郵便番号
      # @return [Array<PostalCode>]
      def where(code:)
        normalized = code.to_s.delete("-")
        return [] unless normalized.match?(/\A\d{7}\z/)

        prefix = normalized[0..2]
        Data::Loader.postal_codes(prefix)
                    .filter_map { |data| new(**data) if data[:code] == normalized }
      end
    end
  end
end
