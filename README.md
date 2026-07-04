# CryptocurrencyPrices

A small Rails 8 API that serves cryptocurrency prices fetched from
[CoinGecko](https://www.coingecko.com/) and served out of a shared cache.

There is **no database** — the app is stateless. Prices are fetched from
CoinGecko by a rake task (intended to be run on a schedule via cron) and
stored in Memcached, which both the cron process and the running web server
read from.

## Requirements

* Docker and Docker Compose (the whole stack, including Ruby, runs in
  containers — no local Ruby install required)
* A CoinGecko API key (a free
  [Demo key](https://www.coingecko.com/en/api/pricing) works)

## Setup

1. Copy the env file and fill in your CoinGecko key:

   ```
   cp .env.example .env
   ```

   Edit `.env` and set `COINGECKO_API_KEY=<your key>`. `RAILS_ENV` and
   `APP_PORT` already have sensible defaults.

2. Build and start the stack:

   ```
   docker compose up -d --build
   ```

   This starts two containers:
   * `app` — the Rails server, published on `http://localhost:${APP_PORT}` (default `3000`)
   * `memcached` — the shared cache backend

3. Check it booted:

   ```
   curl http://localhost:3000/up
   ```

## API

### `GET /prices/:symbol`

Returns the last cached price for a ticker symbol (case-insensitive, e.g.
`BTC`, `btc`, `Eth`). The price only comes from cache — this endpoint never
calls CoinGecko directly, so it stays fast and keeps working even if
CoinGecko is down (see [Background price updates](#background-price-updates)).

Success:

```
curl http://localhost:3000/prices/BTC
# {"symbol":"BTC","price":67210.5}
```

Nothing cached yet for that symbol (either it's not a known CoinGecko symbol,
or the updater hasn't run yet):

```
curl http://localhost:3000/prices/nonexistent
# 404 {"error":"Price not available yet"}
```

## Background price updates

`Coingecko::CoinDataUpdater` (`app/services/coingecko/coin_data_updater.rb`)
fetches the full CoinGecko market list (via `CoingeckoRest::CoinList`,
`app/clients/coingecko_rest/`) and writes each coin's current price into
the cache, keyed by its uppercased symbol (`coingecko/BTC`, `coingecko/ETH`,
...). This is what `/prices/:symbol` reads from.

It's exposed as a rake task:

```
bin/rails coin_data:update
```

Run it once manually against the running stack with:

```
docker compose exec app ruby bin/rails coin_data:update
```

Each run logs a summary (coin count) to `log/coin_data_updater.log`.

### Running it on a schedule (cron)

The task is meant to be invoked every minute. Inside the `app` container:

```
* * * * * cd /rails && ruby bin/rails coin_data:update >> log/cron.log 2>&1
```

(There's currently no cron daemon wired into the container itself — the
crontab entry above needs to be installed wherever you choose to run it,
e.g. inside the container via `crontab`/`supercronic`, or on the host
against `docker compose exec`.)

## Caching

`Rails.cache` is backed by Memcached (`config.cache_store = :mem_cache_store`,
see `config/environments/development.rb` / `production.rb`), pointed at the
`memcached` service via `MEMCACHED_URL`. This matters because the price
updater and the web server are **separate processes** — an in-process store
like `:memory_store` would never let the cron-invoked updater's writes reach
the running server. Memcached is shared across both.

Cache keys never expire — the updater simply overwrites the previous value
on each successful run, so `/prices/:symbol` keeps serving the last known
price even if a given update run fails or CoinGecko is temporarily
unavailable.

## Running tests

Tests use RSpec, with WebMock stubbing all CoinGecko HTTP calls (no real
network access, no live API key needed):

```
docker compose exec -e RAILS_ENV=test app ruby bin/rspec
```

The explicit `-e RAILS_ENV=test` matters: the `app` container's environment
already has `RAILS_ENV=development` baked in (from `.env`/`docker-compose.yml`),
which takes precedence over the `ENV['RAILS_ENV'] ||= 'test'` fallback in
`spec/rails_helper.rb`. Without the override, specs would silently run
against the development environment.

Specs live under `spec/`, mirroring `app/` (e.g.
`spec/services/coingecko/coin_data_updater_spec.rb`), plus request specs
under `spec/requests/` for the HTTP-facing behavior.

## Project structure

* `app/clients/coingecko_rest/` — thin HTTParty wrapper around the CoinGecko
  REST API (`Base` holds the base URI/headers, `CoinList` hits
  `/coins/markets`). Returns raw `HTTParty::Response` objects.
* `app/services/coingecko/` — business logic built on top of the client:
  `CoinDataUpdater` (fetch + cache) and `CoinPriceFetcher` (cache-only read).
* `app/controllers/prices_controller.rb` — the `/prices/:symbol` endpoint.
* `lib/tasks/coin_data.rake` — the `coin_data:update` rake task.

## Useful commands

```
# Rails console
docker compose exec app ruby bin/rails console

# Logs
docker compose logs -f app

# Stop everything
docker compose down
```
