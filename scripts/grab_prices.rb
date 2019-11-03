# frozen_string_literal: true

# Get dependencies:
#
#   gem install nokogiri
#   gem install parallel

require 'csv'
require 'Parallel'
require 'fileutils'

require_relative '../lib/tv_prices'

# Shorthand
C = TvPrices::Config

Dir.mkdir(C::HISTORY_DIR) unless Dir.exists?(C::HISTORY_DIR)

unless Dir.exists?(C::CACHED_DIR)
  Dir.mkdir(C::CACHED_DIR)
  File.write(TvPrices.last_updated_file, Time.now.to_i)
end

all_stores = C::ALL_CONFIGS.map { |cfg| cfg.fetch(:store) }

Parallel.each(all_stores) do |store|
  dir = TvPrices.store_dir(store)
  Dir.mkdir(dir) unless Dir.exist?(dir)
end

results =
  Parallel
  .flat_map(C::ALL_CONFIGS) { |cfg| TvPrices::TvScraper.all_results(cfg) }
  .sort_by { |i| TvPrices.sortable_array(i) }
  .group_by { |i| i[:url] }
  .values
  .map(&:first)

history_filename = [File.read(TvPrices.last_updated_file), C::CSV_NAME].join('_')
history_path = File.join(C::HISTORY_DIR, history_filename)

CSV.open(history_path, 'wb') do |csv|
  csv << C::HEADERS
  results.each { |attrs| csv << C::HEADERS.map { |key| attrs[key] } }
end

# The history of prices is kept twice: Once in the HISTORY_DIR, and once in the
# git history of the CSV_NAME file.
FileUtils.cp(history_path, C::CSV_NAME)
