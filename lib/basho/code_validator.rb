# frozen_string_literal: true

module Basho
  # JIS X 0401 チェックディジットによる6桁自治体コードの検証。
  #
  # @example
  #   Basho::CodeValidator.valid?("131016") # => true
  #   Basho::CodeValidator.valid?("131019") # => false
  module CodeValidator
    # チェックディジットの桁位置（0始まり）
    CHECK_DIGITS_INDEX = 5
    # モジュラス演算の基数
    CHECK_BASE = 11
    # 有効な都道府県コード範囲
    PREFECTURE_RANGE = (1..47)

    module_function

    # 自治体コードの形式とチェックディジットを検証する。
    #
    # @param code [String] 6桁自治体コード
    # @return [Boolean]
    def valid?(code)
      return false unless code.is_a?(String) && code.match?(/\A\d{6}\z/)
      return false unless PREFECTURE_RANGE.cover?(code[0..1].to_i)

      code[CHECK_DIGITS_INDEX].to_i == compute_check_digit(code)
    end

    # チェックディジットを計算する。
    #
    # @param code [String] 6桁自治体コード
    # @return [Integer] 0〜9のチェックディジット
    def compute_check_digit(code)
      sub_total = code.chars
                      .take(CHECK_DIGITS_INDEX)
                      .map.with_index { |digit, i| digit.to_i * (CHECK_DIGITS_INDEX - i + 1) }
                      .sum

      candidate = (CHECK_BASE - (sub_total % CHECK_BASE)) % 10
      sub_total >= CHECK_BASE ? candidate : CHECK_BASE - sub_total
    end
  end
end
