# frozen_string_literal: true

require_relative 'config'
require_relative 'sort_results'

module TvPrices
  class << self
    def store_dir(store)
      File.join(Config::CACHED_DIR, store)
    end

    def last_updated_file
      File.join(Config::CACHED_DIR, Config::LAST_UPDATED_FILE)
    end

    def map_histories
      return to_enum(:map_histories) unless block_given?

      Parallel.map(Dir.glob(File.join(Config::HISTORY_DIR, '*.csv'))) do |path|
        csv = CSV.read(path)
        header = csv.first.map(&:to_sym)
        data = csv[1..].map { |row| row_to_hash(row, header) }

        yield(path, data)
      end
    end

    private

    def row_to_hash(row, header)
      header.zip(row).to_h.tap do |hash|
        hash[:size] = SortResults.just_number(hash[:size])
        hash[:price] = SortResults.just_number(hash[:price])
      end
    end
  end
end

require_relative 'format_price'
require_relative 'get_from_cache_or_web'
require_relative 'html_tv_scraper'
require_relative 'json_tv_scraper'
require_relative 'maybe'
require_relative 'parse_title'
require_relative 'tv_scraper'
