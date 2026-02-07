# frozen_string_literal: true

RSpec.describe JpAddress::ActiveRecord::Base do
  let(:model_class) do
    Class.new do
      include JpAddress

      attr_accessor :local_gov_code, :postal_code

      jp_address :local_gov_code
      jp_address_postal :postal_code

      def initialize(local_gov_code: nil, postal_code: nil)
        @local_gov_code = local_gov_code
        @postal_code = postal_code
      end
    end
  end

  describe "jp_address" do
    context "有効な自治体コード" do
      let(:record) { model_class.new(local_gov_code: "131016") }

      it "prefectureを返す" do
        expect(record.prefecture).to be_a(JpAddress::Prefecture)
        expect(record.prefecture.name).to eq("東京都")
      end

      it "cityを返す" do
        expect(record.city).to be_a(JpAddress::City)
        expect(record.city.name).to eq("千代田区")
      end

      it "full_addressを返す" do
        expect(record.full_address).to eq("東京都千代田区")
      end
    end

    context "nilの場合" do
      let(:record) { model_class.new(local_gov_code: nil) }

      it "prefectureはnilを返す" do
        expect(record.prefecture).to be_nil
      end

      it "cityはnilを返す" do
        expect(record.city).to be_nil
      end

      it "full_addressはnilを返す" do
        expect(record.full_address).to be_nil
      end
    end
  end

  describe "jp_address_postal" do
    context "有効な郵便番号" do
      let(:record) { model_class.new(postal_code: "1540011") }

      it "postal_addressを返す" do
        expect(record.postal_address).to eq("東京都世田谷区上馬")
      end
    end

    context "ハイフン付き" do
      let(:record) { model_class.new(postal_code: "154-0011") }

      it "postal_addressを返す" do
        expect(record.postal_address).to eq("東京都世田谷区上馬")
      end
    end

    context "nilの場合" do
      let(:record) { model_class.new(postal_code: nil) }

      it "postal_addressはnilを返す" do
        expect(record.postal_address).to be_nil
      end
    end
  end
end
