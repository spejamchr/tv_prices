# frozen_string_literal: true

# The CSV format occasionally changes. This updates past CSVs to match the
# current format, using the `title` column in the CSV.

require 'csv'
require 'Parallel'

require_relative '../lib/tv_prices'

# Shorthand
C = TvPrices::Config

exit unless Dir.exists?(C::HISTORY_DIR)

module TvPrices
  module Refresher
    extend ParseTitle
    extend FormatPrice

    def self.attributes(row)
      basic_attributes(row[:title])
        .assign(:store) { row[:store] }
        .assign(:price) { format_price(row[:price]) }
        .assign(:url) { row[:url] }
        .assign(:page) { row[:page] }
    end
  end
end

Parallel.each(Dir.glob(File.join(C::HISTORY_DIR, '*.csv'))) do |path|
  csv = CSV.read(path)
  header = csv.first.map(&:to_sym)

  data =
    csv[1..]
    .map { |row| header.zip(row).to_h }
    .map { |row| TvPrices::Refresher.attributes(row) }
    .yield_self { |rows| TvPrices::Maybe.only_justs(rows) }
    .yield_self { |rows| TvPrices::SortResults.sort_results(rows) }

  CSV.open(path, 'wb') do |csv|
    csv << C::HEADERS
    data.each { |attrs| csv << C::HEADERS.map  { |key| attrs[key] } }
  end
end
