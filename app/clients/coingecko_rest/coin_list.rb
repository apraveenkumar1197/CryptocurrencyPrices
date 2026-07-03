module CoingeckoRest
  class CoinList < Base
    PATH = "/coins/markets?vs_currency=usd".freeze

    def fetch
      get(PATH)
    end
  end
end
