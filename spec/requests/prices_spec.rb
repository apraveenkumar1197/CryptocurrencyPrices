require "rails_helper"

RSpec.describe "Prices", type: :request do
  before do
    Rails.cache.clear
  end

  describe "GET /prices/:symbol" do
    context "when a price is cached for the symbol" do
      before do
        Rails.cache.write("coingecko/BTC", { price: 67210.5 })
      end

      it "returns 200 with the serialized price" do
        get "/prices/BTC"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("symbol" => "BTC", "price" => 67210.5)
      end

      it "matches the symbol case-insensitively" do
        get "/prices/btc"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("symbol" => "BTC", "price" => 67210.5)
      end
    end

    context "when nothing is cached for the symbol" do
      it "returns 404 with an error message" do
        get "/prices/DOGE"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq("error" => "Price not available yet")
      end
    end
  end
end
