# frozen_string_literal: true

require 'json'

require_relative 'get_from_cache_or_web'

module TvPrices
  # Parse TV info from a list of JSON objects
  class JsonTvScraper < TvScraper
    include TvPrices::GetFromCacheOrWeb

    private

    def get_json(uri, store, page)
      json = get_from_cache_or_web(uri, store, page) do |options|
        options.merge('Accept' => 'application/json')
      end

      JSON.parse(json)
    end

    def items(page)
      uri = pagination.call(page)
      json = get_json(uri, store, page)
      fetch(json, item_query).get_or_else([])
    end

    def fetch(item, query)
      Maybe
        .new(item.dig(*query))
        .or_effect { puts "Could not fetch field: #{query}" if Config::DEBUG }
    end

    def item_title(item)
      fetch(item, title_query).get_or_else('')
    end

    def item_ref(item)
      fetch(item, url_query)
    end

    def item_price(item)
      fetch(item, price_query)
        .map { |n| format('%.2f', n) }
        .map { |s| s.reverse.scan(/(\d*\.\d{1,3}|\d{1,3})/).join(',').reverse }
        .map { |s| "$#{s}" }
        .or_effect { item_url(item).effect { |a| p a if Config::DEBUG } }
    end
  end
end
