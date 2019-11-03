# frozen_string_literal: true

require_relative 'config'

module TvPrices
  class << self
    def store_dir(store)
      File.join(Config::CACHED_DIR, store)
    end

    def last_updated_file
      File.join(Config::CACHED_DIR, Config::LAST_UPDATED_FILE)
    end
  end
end

require_relative 'format_price'
require_relative 'get_from_cache_or_web'
require_relative 'html_tv_scraper'
require_relative 'json_tv_scraper'
require_relative 'maybe'
require_relative 'parse_title'
require_relative 'sort_results'
require_relative 'tv_scraper'
