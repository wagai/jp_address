# frozen_string_literal: true

require_relative "basho/version"
require_relative "basho/data/loader"
require_relative "basho/region"
require_relative "basho/prefecture"
require_relative "basho/code_validator"
require_relative "basho/city"
require_relative "basho/postal_code"
require_relative "basho/active_record/base"
require_relative "basho/engine" if defined?(Rails::Engine)

# 日本の住所データ（都道府県・市区町村・郵便番号・地方区分）を統一的に扱うgem。
#
# デフォルトでは同梱のJSONファイルからデータを読み込む。
# +basho_prefectures+ / +basho_cities+ テーブルが存在すれば自動的にDBバックエンドに切り替わる。
#
# @example ActiveRecordモデルでの利用
#   class Shop < ApplicationRecord
#     include Basho
#     basho :city_code
#     basho_postal :postal_code, prefecture: :pref_name, city: :city_name
#   end
module Basho
  # basho gem固有のエラー基底クラス
  class Error < StandardError; end

  @db_mutex = Mutex.new

  # +basho_prefectures+ テーブルが存在するかを検出する。
  # 結果はプロセスの生存期間中キャッシュされる。スレッドセーフ。
  #
  # @return [Boolean] DBバックエンドが利用可能なら +true+
  def self.db?
    return @db if defined?(@db)

    @db_mutex.synchronize do
      return @db if defined?(@db)

      @db = defined?(::ActiveRecord::Base) &&
            ::ActiveRecord::Base.connection.table_exists?("basho_prefectures")
      require "basho/db" if @db
      @db
    end
  rescue ::ActiveRecord::ConnectionNotEstablished, ::ActiveRecord::NoDatabaseError
    @db = false
  end

  # DB検出キャッシュをリセットする。テスト時やマイグレーション後の再検出に使用。
  #
  # @return [void]
  def self.reset_db_cache!
    remove_instance_variable(:@db) if defined?(@db)
    Prefecture.reset_cache! if Prefecture.respond_to?(:reset_cache!)
  end

  # バックエンドを強制指定する。主にテスト用。
  #
  # @param value [Boolean] +true+ でDBバックエンド、+false+ でメモリバックエンド
  # @return [void]
  def self.db=(value)
    @db = value
    require "basho/db" if value
  end

  # @private
  def self.included(base)
    base.extend ActiveRecord::Base
  end
end
