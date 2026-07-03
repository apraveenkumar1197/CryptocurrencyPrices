module Coingecko
  class CoinPriceFetcher
    attr_accessor :symbol

    def initialize(symbol)
      @symbol = symbol
    end

    def call
      Rails.cache.read(cache_key)
    end

    private

    def cache_key
      "coingecko/#{symbol.upcase}"
    end
  end
end
