namespace :coin_data do
  desc "Fetch coin prices from CoinGecko and store them in cache"
  task update: :environment do
    Coingecko::CoinDataUpdater.new.call
  end
end
