class PricesController < ApplicationController
  def show
    symbol = symbol_params[:symbol].to_s.upcase
    cached = Coingecko::CoinPriceFetcher.new(symbol).call

    if cached.nil?
      render json: { error: "Price not available yet" }, status: :not_found
    else
      render json: PriceSerializer.new(symbol: symbol, price: cached[:price])
    end
  end

  private

  def symbol_params
    params.permit(:symbol)
  end
end
