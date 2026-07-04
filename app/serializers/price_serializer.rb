class PriceSerializer
  def initialize(symbol:, price:)
    @symbol = symbol
    @price = price
  end

  def as_json(*)
    { symbol: @symbol, price: @price }
  end
end
