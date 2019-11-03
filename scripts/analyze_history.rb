# frozen_string_literal: true

# Analyze changes in TV pricing over time

require 'csv'
require 'Parallel'

require_relative '../lib/tv_prices'

exit unless Dir.exists?(TvPrices::Config::HISTORY_DIR)

filters = {
  brand: %w[LG SAMSUNG SONY],
  size: (65..65),
  resolution: %w[2160p],
  tech: %w[LED],
  store: %w[Costco Best\ Buy Walmart],
}

results =
  TvPrices.map_histories do |path, data|
    time = Time.at(path.scan(/\d+/).join.to_i)
    filtered = data.filter do |row|
      filters.all? { |k, v| v.include?(row[k]) }
    end
    [time, filtered]
  end.to_h

columns = {
  'Time' => 25,
  'Count' => 5,
  'Min' => 10,
  'Avg' => 10,
  'Med' => 10,
  'Max' => 10,
}

title = columns.map { |k, v| k.center(v) }.join(' | ')

puts title
puts "=" * title.length

o = Object.new.extend(TvPrices::FormatPrice)

results.keys.sort.each do |time|
  batch = results[time]
  count = batch.count
  next if count.zero?

  prices = batch.map { |r| r[:price] }

  min = prices.min
  avg = prices.sum / count
  med = prices.sort[count / 2]
  max = prices.max

  puts [
    time.to_s,
    count.to_s,
    o.format_price(min),
    o.format_price(avg),
    o.format_price(med),
    o.format_price(max),
  ].zip(columns.values).map { |s, n| s.rjust(n) }.join(' | ')
end
