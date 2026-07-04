require "rails_helper"

RSpec.describe Coingecko::CoinDataUpdater do
  COINGECKO_URL = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd".freeze

  before do
    Rails.cache.clear
  end

  def stub_coingecko(coins)
    stub_request(:get, COINGECKO_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: coins.to_json
    )
  end

  describe "#call" do
    it "writes each coin's price into the cache under its uppercased symbol" do
      stub_coingecko([
        { "symbol" => "btc", "current_price" => 67000.5 },
        { "symbol" => "eth", "current_price" => 3000.25 }
      ])

      described_class.new.call

      expect(Rails.cache.read("coingecko/BTC")).to eq(price: 67000.5)
      expect(Rails.cache.read("coingecko/ETH")).to eq(price: 3000.25)
    end

    it "uppercases a lowercase symbol when building the cache key" do
      stub_coingecko([ { "symbol" => "doge", "current_price" => 0.15 } ])

      described_class.new.call

      expect(Rails.cache.read("coingecko/DOGE")).to eq(price: 0.15)
      expect(Rails.cache.read("coingecko/doge")).to be_nil
    end

    it "overwrites an earlier cached price on a later successful run" do
      stub_coingecko([ { "symbol" => "btc", "current_price" => 100 } ])
      described_class.new.call
      expect(Rails.cache.read("coingecko/BTC")).to eq(price: 100)

      stub_coingecko([ { "symbol" => "btc", "current_price" => 200 } ])
      described_class.new.call

      expect(Rails.cache.read("coingecko/BTC")).to eq(price: 200)
    end

    context "when the CoinGecko request fails" do
      it "does not raise when the request fails outright" do
        stub_request(:get, COINGECKO_URL).to_raise(StandardError.new("connection reset"))

        expect { described_class.new.call }.not_to raise_error
      end

      it "does not raise when the request times out" do
        stub_request(:get, COINGECKO_URL).to_timeout

        expect { described_class.new.call }.not_to raise_error
      end

      it "leaves previously cached prices untouched" do
        Rails.cache.write("coingecko/BTC", { price: 100 })
        stub_request(:get, COINGECKO_URL).to_raise(StandardError.new("connection reset"))

        described_class.new.call

        expect(Rails.cache.read("coingecko/BTC")).to eq(price: 100)
      end

      it "leaves a symbol that was never cached as nil" do
        stub_request(:get, COINGECKO_URL).to_timeout

        described_class.new.call

        expect(Rails.cache.read("coingecko/BTC")).to be_nil
      end
    end
  end
end
