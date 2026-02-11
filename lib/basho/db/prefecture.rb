# frozen_string_literal: true

module Basho
  module DB
    # 都道府県のActiveRecordモデル（+basho_prefectures+ テーブル）。
    # メモリ版 {Basho::Prefecture} と同じAPI（+type+, +region+, +capital+）を提供する。
    class Prefecture < ::ActiveRecord::Base
      self.table_name = "basho_prefectures"
      self.primary_key = "code"

      has_many :cities,
               class_name: "Basho::DB::City",
               foreign_key: :prefecture_code,
               inverse_of: :prefecture

      # @return [String] 種別（"都" / "道" / "府" / "県"）
      def type = prefecture_type

      # @return [Region]
      def region = Region.find(region_name)

      # @return [DB::City, nil] 県庁所在地
      def capital = capital_code && Basho::DB::City.find_by(code: capital_code)
    end
  end
end
