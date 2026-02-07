# frozen_string_literal: true

require "rails_helper"

RSpec.describe JpAddress::FormHelper, type: :helper do
  describe "#jp_address_autofill_frame_tag" do
    it "turbo-frameタグを生成する" do
      html = helper.jp_address_autofill_frame_tag

      expect(html).to include("turbo-frame")
      expect(html).to include('id="jp-address-result"')
      expect(html).to include('data-jp-address--auto-fill-target="frame"')
    end
  end
end
