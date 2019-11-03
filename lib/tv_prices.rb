# frozen_string_literal: true

require_relative 'config'

module TvPrices
  class << self
    def sortable_array(hash)
      # I'm intentionally leaving out the title
      [
        just_number(hash[:size]),
        hash[:tech],
        just_number(hash[:resolution]),
        just_number(hash[:price]),
        hash[:brand],
        hash[:store],
        just_number(hash[:page]),
        hash[:url]
      ]
    end

    def store_dir(store)
      File.join(Config::CACHED_DIR, store)
    end

    def last_updated_file
      File.join(Config::CACHED_DIR, Config::LAST_UPDATED_FILE)
    end

    private

    def just_number(string)
      string.to_s.gsub(/[^\d\.]/, '').to_f
    end
  end
end

require_relative 'get_from_cache_or_web'
require_relative 'html_tv_scraper'
require_relative 'json_tv_scraper'
require_relative 'maybe'
require_relative 'parse_title'
require_relative 'tv_scraper'
