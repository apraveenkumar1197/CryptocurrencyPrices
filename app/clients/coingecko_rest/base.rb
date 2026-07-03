module CoingeckoRest
  class Base
    include HTTParty

    base_uri "https://api.coingecko.com/api/v3"

    def initialize
      self.class.headers "x-cg-demo-api-key" => ENV.fetch("COINGECKO_API_KEY", nil)
    end

    def get(path, query: {})
      self.class.get(path, query: query)
    end
  end
end
