# frozen_string_literal: true

module Basho
  module DB
    # 市区町村のActiveRecordモデル（+basho_cities+ テーブル）。
    # メモリ版 {Basho::City} と同じAPI（+full_name+, +capital?+）を提供する。
    class City < ::ActiveRecord::Base
      self.table_name = "basho_cities"
      self.primary_key = "code"

      belongs_to :prefecture,
                 class_name: "Basho::DB::Prefecture",
                 foreign_key: :prefecture_code,
                 inverse_of: :cities

      # 郡名付きの正式名を返す。
      #
      # @return [String]
      def full_name
        district ? "#{district}#{name}" : name
      end
    end
  end
end
