module CoingeckoRest
  class CoinList < Base

    def fetch
      get(url)
    end

    def url
      "/coins/markets?vs_currency=usd".freeze
    end
  end
end
