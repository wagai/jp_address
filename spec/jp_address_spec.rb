# frozen_string_literal: true

RSpec.describe JpAddress do
  it "バージョン番号がある" do
    expect(JpAddress::VERSION).not_to be_nil
  end
end
