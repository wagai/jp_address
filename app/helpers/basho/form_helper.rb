# frozen_string_literal: true

module Basho
  # 郵便番号自動入力用のフォームヘルパー
  module FormHelper
    def basho_autofill_frame_tag
      content_tag("turbo-frame", nil, id: "basho-result",
                                      data: { "basho--auto-fill-target" => "frame",
                                              action: "turbo:frame-load->basho--auto-fill#fill" })
    end
  end
end
