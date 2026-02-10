# frozen_string_literal: true

require "rails_helper"

RSpec.describe Basho::FormHelper, type: :helper do
  describe "#basho_autofill_frame_tag" do
    it "turbo-frameタグを生成する" do
      html = helper.basho_autofill_frame_tag

      expect(html).to include("turbo-frame")
      expect(html).to include('id="basho-result"')
      expect(html).to include('data-basho--auto-fill-target="frame"')
      expect(html).to include('data-action="turbo:frame-load-&gt;basho--auto-fill#fill"')
    end
  end
end
