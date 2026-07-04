require "rails_helper"

RSpec.describe Coingecko::CoinPriceFetcher do
  before do
    Rails.cache.clear
  end

  describe "#call" do
    it "returns nil when nothing has been cached for the symbol" do
      expect(described_class.new("BTC").call).to be_nil
    end

    it "returns the cached value for the symbol" do
      Rails.cache.write("coingecko/BTC", { price: 67000.5 })

      expect(described_class.new("BTC").call).to eq(price: 67000.5)
    end

    it "looks up the cache key case-insensitively" do
      Rails.cache.write("coingecko/ETH", { price: 3000 })

      expect(described_class.new("eth").call).to eq(described_class.new("ETH").call)
    end

    it "reflects the latest cached value once it has been overwritten" do
      Rails.cache.write("coingecko/BTC", { price: 100 })
      Rails.cache.write("coingecko/BTC", { price: 200 })

      expect(described_class.new("BTC").call).to eq(price: 200)
    end
  end
end
