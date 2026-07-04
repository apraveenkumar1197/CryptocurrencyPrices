module Coingecko
  class CoinDataUpdater
    LOG_FILE = Rails.root.join("log", "coin_data_updater.log")

    def call
      write_into_cache
      write_a_log
    rescue StandardError => e
      logger.error("CoinDataUpdater - Failed to update #{e.message}")
    end

    private

    def write_into_cache
      coin_list.each do |coin|
        Rails.cache.write("coingecko/#{coin['symbol'].upcase}", { price: coin["current_price"] })
      end
    end

    def coin_list
      @coin_list ||= CoingeckoRest::CoinList.new.fetch
    end

    def write_a_log
      logger.info("CoinDataUpdater - Coin Count: #{coin_list.size}")
    end

    def logger
      @logger ||= Logger.new(LOG_FILE)
    end
  end
end
