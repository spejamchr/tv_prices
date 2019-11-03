# frozen_string_literal: true

module TvPrices
  module FormatPrice
    def format_price(price)
      '$' +
        format('%.2f', price.to_s.gsub(/[^\d\.]/, ''))
        .reverse
        .scan(/(\d*\.\d{1,3}|\d{1,3})/)
        .join(',')
        .reverse
    end
  end
end
