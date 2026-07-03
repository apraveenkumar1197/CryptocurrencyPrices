class PricesController < ApplicationController
  def show
    price = Coingecko::CoinPriceFetcher.new(symbol_params[:symbol]).call

    Rails.logger.info "#{symbol_params[:symbol]} ---  #{price}"
    if price.nil?
      render json: { error: "Price not available yet" }, status: :not_found
    else
      render json: price
    end
  end

  private

  def symbol_params
    params.permit(:symbol)
  end
end
