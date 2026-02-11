# frozen_string_literal: true

module Basho
  # 都道府県を表すイミュータブルなデータクラス。
  #
  # DBバックエンドが有効な場合、クラスメソッドは自動的に {DB::Prefecture} 経由で検索する。
  #
  # @!attribute [r] code
  #   @return [Integer] JIS X 0401 都道府県コード（1〜47）
  # @!attribute [r] name
  #   @return [String] 都道府県名（例: "東京都"）
  # @!attribute [r] name_en
  #   @return [String] 英語名（例: "Tokyo"）
  # @!attribute [r] name_kana
  #   @return [String] カタカナ名（例: "トウキョウト"）
  # @!attribute [r] name_hiragana
  #   @return [String] ひらがな名（例: "とうきょうと"）
  # @!attribute [r] region_name
  #   @return [String] 地方名（例: "関東"）
  # @!attribute [r] type
  #   @return [String] 種別（"都" / "道" / "府" / "県"）
  # @!attribute [r] capital_code
  #   @return [String] 県庁所在地の6桁自治体コード（例: "131041"）
  Prefecture = ::Data.define(:code, :name, :name_en, :name_kana, :name_hiragana, :region_name, :type, :capital_code) do
    # 所属する地方を返す。
    #
    # @return [Region]
    def region
      Region.find(region_name)
    end

    # 所属する市区町村の一覧を返す。
    #
    # @return [Array<City>, Array<DB::City>]
    def cities
      City.where(prefecture_code: code)
    end

    # 県庁所在地を返す。
    #
    # @return [City, DB::City, nil]
    def capital
      City.find(capital_code)
    end

    class << self
      # 全47都道府県を返す。
      #
      # @return [Array<Prefecture>, Array<DB::Prefecture>]
      def all
        return DB::Prefecture.all.to_a if Basho.db?

        @all ||= Data::Loader.prefectures.map { |data| new(**data) }.freeze
      end

      # 都道府県を検索する。
      #
      # @overload find(code)
      #   @param code [Integer] 都道府県コード
      # @overload find(name:)
      #   @param name [String] 日本語名（例: "東京都"）
      # @overload find(name_en:)
      #   @param name_en [String] 英語名（例: "Tokyo"）
      # @return [Prefecture, DB::Prefecture, nil]
      def find(code = nil, **options)
        attrs = code.nil? ? options : { code: code }
        return if attrs.empty?

        key, value = attrs.first
        return DB::Prefecture.find_by(key => value) if Basho.db?

        all.find { |pref| pref.public_send(key) == value }
      end

      # 都道府県を地方名で絞り込む。引数なしで全件返す。
      #
      # @param region [String, nil] 地方名（例: "関東"）
      # @return [Array<Prefecture>, Array<DB::Prefecture>]
      def where(region: nil)
        return all unless region
        return DB::Prefecture.where(region_name: region).to_a if Basho.db?

        all.select { |pref| pref.region_name == region }
      end

      # メモリキャッシュをクリアする。
      #
      # @return [void]
      # @api private
      def reset_cache!
        remove_instance_variable(:@all) if defined?(@all)
      end
    end
  end
end
