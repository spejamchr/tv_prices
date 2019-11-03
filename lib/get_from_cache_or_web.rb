# frozen_string_literal: true

require 'open-uri'

require './lib/tv_prices'

module TvPrices
  module GetFromCacheOrWeb
    private

    def get_from_cache_or_web(uri, store, page)
      path = File.join(TvPrices.store_dir(store), "page_#{page}.html")

      unless File.readable?(path)
        puts "Fetching web page at #{uri}"
        options = block_given? ? yield(Config::URI_OPTIONS) : Config::URI_OPTIONS
        URI.parse(uri).open(options) { |f| File.write(path, f.read) }
      end

      File.read(path)
    end
  end
end
