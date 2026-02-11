# frozen_string_literal: true

RSpec.describe Basho::City do
  describe ".find" do
    it "自治体コードで検索できる" do
      city = described_class.find("131016")
      expect(city.code).to eq("131016")
      expect(city.name).to eq("千代田区")
      expect(city.name_kana).to eq("チヨダク")
      expect(city.prefecture_code).to eq(13)
    end

    it "県庁所在地フラグを持つ" do
      city = described_class.find("131041")
      expect(city.name).to eq("新宿区")
      expect(city.capital?).to be true
    end

    it "県庁所在地でない場合はfalse" do
      city = described_class.find("131016")
      expect(city.capital?).to be false
    end

    it "存在しないコードはnilを返す" do
      expect(described_class.find("999999")).to be_nil
    end

    it "不正な形式はnilを返す" do
      expect(described_class.find(nil)).to be_nil
      expect(described_class.find("123")).to be_nil
    end
  end

  describe ".where" do
    it "都道府県コードで絞り込みできる" do
      cities = described_class.where(prefecture_code: 13)
      expect(cities).to be_an(Array)
      expect(cities.size).to be > 0
      expect(cities.map(&:name)).to include("千代田区", "新宿区", "渋谷区")
    end

    it "各市区町村がprefecture_codeを持つ" do
      cities = described_class.where(prefecture_code: 1)
      cities.each do |city|
        expect(city.prefecture_code).to eq(1)
      end
    end
  end

  describe ".valid_code?" do
    it "正しい自治体コードはtrueを返す" do
      expect(described_class.valid_code?("131016")).to be true
      expect(described_class.valid_code?("011002")).to be true
    end

    it "不正な自治体コードはfalseを返す" do
      expect(described_class.valid_code?("131019")).to be false
      expect(described_class.valid_code?("000000")).to be false
    end

    it "不正な形式はfalseを返す" do
      expect(described_class.valid_code?("12345")).to be false
      expect(described_class.valid_code?("1234567")).to be false
      expect(described_class.valid_code?(nil)).to be false
    end
  end

  # ── 廃止・合併 ──────────────────────────────────

  describe "廃止・合併" do
    # デフォルトチェーン: A(旧A区) → B(旧B区) → C(千代田区=実在アクティブ)
    let(:city_a) do
      {
        code: "130001",
        prefecture_code: 13,
        name: "旧A区",
        name_kana: "キュウエーク",
        deprecated_at: "2024-01-01",
        successor_code: "130002"
      }
    end

    let(:city_b) do
      {
        code: "130002",
        prefecture_code: 13,
        name: "旧B区",
        name_kana: "キュウビーク",
        deprecated_at: "2025-04-01",
        successor_code: "131016"
      }
    end

    let(:deprecated_entries) { [city_a, city_b] }

    before do
      allow(Basho::Data::Loader).to receive(:deprecated_cities).and_return(deprecated_entries)
    end

    after { Basho::Data::Loader.reset! }

    describe "後方互換" do
      it "既存のアクティブ市区町村は deprecated_at: nil, successor_code: nil を持つ" do
        city = described_class.find("131016")
        expect(city.deprecated_at).to be_nil
        expect(city.successor_code).to be_nil
      end
    end

    describe ".find" do
      it "廃止コードで検索できる" do
        city = described_class.find("130001")
        expect(city.name).to eq("旧A区")
        expect(city.deprecated_at).to eq("2024-01-01")
        expect(city.successor_code).to eq("130002")
      end

      it "アクティブデータを優先する" do
        city = described_class.find("131016")
        expect(city.name).to eq("千代田区")
        expect(city).to be_active
      end

      it "廃止JSONにもアクティブJSONにもないコードは nil" do
        expect(described_class.find("139999")).to be_nil
      end
    end

    describe ".where" do
      it "廃止コードを含まない" do
        codes = described_class.where(prefecture_code: 13).map(&:code)
        expect(codes).not_to include("130001", "130002")
      end
    end

    describe "#deprecated? / #active?" do
      it "deprecated_at なし → active かつ not deprecated" do
        city = described_class.find("131016")
        expect(city).to be_active
        expect(city).not_to be_deprecated
      end

      it "deprecated_at あり → deprecated かつ not active" do
        city = described_class.find("130001")
        expect(city).to be_deprecated
        expect(city).not_to be_active
      end
    end

    describe "#successor" do
      it "successor_code がある場合、合併先を返す" do
        city = described_class.find("130001")
        expect(city.successor.code).to eq("130002")
      end

      it "successor_code が nil なら nil" do
        city = described_class.find("131016")
        expect(city.successor).to be_nil
      end

      context "存在しない successor_code" do
        let(:deprecated_entries) { [city_a.merge(successor_code: "999999")] }

        it "nil を返す" do
          city = described_class.find("130001")
          expect(city.successor).to be_nil
        end
      end
    end

    describe "#current" do
      it "successor なし → 自身を返す" do
        city = described_class.find("131016")
        expect(city.current).to eq(city)
      end

      it "チェーン A→B→C → 終端 C を返す" do
        current = described_class.find("130001").current
        expect(current.code).to eq("131016")
        expect(current).to be_active
      end

      it "中間から辿っても終端に到達する（B→C）" do
        expect(described_class.find("130002").current.code).to eq("131016")
      end

      context "ループ A→B→A" do
        let(:deprecated_entries) do
          [
            city_a.merge(successor_code: "130002"),
            city_b.merge(successor_code: "130001")
          ]
        end

        it "無限ループせず停止する" do
          city = described_class.find("130001")
          expect { city.current }.not_to raise_error
          expect(%w[130001 130002]).to include(city.current.code)
        end
      end

      context "存在しない successor_code" do
        let(:deprecated_entries) { [city_a.merge(successor_code: "999999")] }

        it "自身を返す" do
          city = described_class.find("130001")
          expect(city.current).to eq(city)
        end
      end
    end
  end

  describe "#prefecture" do
    it "所属する都道府県を返す" do
      city = described_class.find("131016")
      expect(city.prefecture.name).to eq("東京都")
    end
  end

  describe "#district" do
    it "郡に属する町村は郡名を持つ" do
      city = described_class.find("473626")
      expect(city.name).to eq("八重瀬町")
      expect(city.district).to eq("島尻郡")
    end

    it "市・区は郡名を持たない" do
      city = described_class.find("131016")
      expect(city.district).to be_nil
    end
  end

  describe "#full_name" do
    it "郡名付きの正式名を返す" do
      city = described_class.find("473626")
      expect(city.full_name).to eq("島尻郡八重瀬町")
    end

    it "郡がない場合はnameと同じ" do
      city = described_class.find("131016")
      expect(city.full_name).to eq("千代田区")
    end
  end
end
