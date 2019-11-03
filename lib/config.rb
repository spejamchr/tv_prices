# frozen_string_literal: true

# This file contains configuration for various parts of the scraper
#
# Most of it shouldn't be changed much. However, the DEBUG constant is fine to
# change between runs. It would be nice to make it a runtime argument instead.
module TvPrices
  module Config
    # Whether to output debug-level logging statements
    DEBUG = false

    # Locations for output
    CACHED_DIR = 'cached_pages'
    LAST_UPDATED_FILE = 'last_updated'
    HISTORY_DIR = 'history'
    CSV_NAME = 'scraped_televisions.csv'

    # CSV Headers
    HEADERS = %i[
    url
    page
    title
    store
    brand
    tech
    size
    resolution
    price
    ].freeze

    URI_OPTIONS = {
      # Overstock rejects my requests with a regular Ruby User-Agent. Use
      # Firefox.
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; ' \
      'rv:68.0) Gecko/20100101 Firefox/68.0',
      'From' => 'spensterc@yahoo.com',
      'Referer' => 'http://www.ruby-lang.org/'
    }.freeze

    # Search URIs ##############################################################

    BEST_BUY_URI =
      'https://www.bestbuy.com/site/tvs/all-flat-screen-tvs/abcat0101001.c' \
      '?qp=condition_facet%3DCondition~New'

    COSTCO_URI =
      'https://www.costco.com/televisions.html' \
      '?display-type=led-lcd+oled' \
      '&refine=ads_f110001_ntk_cs%253A%2522LED-LCD%2522|' \
      'ads_f110001_ntk_cs%253A%2522OLED%2522|'

    AMAZON_URI =
      'https://www.amazon.com/Televisions-Television-Video/s?rh=n%3A172659'

    WALMART_URI =
      'https://www.walmart.com/search/api/preso' \
      '?facet=condition%3ANew%7C%7Cvideo_panel_design%3AFlat'

    FRYS_URI =
      'https://www.frys.com/category/Outpost/Video/Televisions'

    NEWEGG_URI =
      'https://www.newegg.com/p/pl?N=100167585%204814'

    TARGET_URI =
      'https://redsky.target.com/v2/plp/search/' \
      '?category=5xtdj' \
      '&default_purchasability_filter=true' \
      '&pricing_store_id=1357' \
      '&store_ids=1357' \
      '&key=eb2551e4accc14f38cc42d32fbc2b2ea'

    OVERSTOCK_URI =
      'https://www.overstock.com/Electronics/Televisions/2171/cat.html' \
      '?format=fusion'

    # Scraper Configuration ####################################################

    BEST_BUY_CONFIG = {
      type: 'html',
      store: 'Best Buy',
      base_url: 'https://www.bestbuy.com',
      item_query: '.sku-item',
      title_query: '.information .sku-title a',
      price_query: '.price-block .priceView-hero-price.priceView-customer-price',
      url_query: '.information .sku-title a @href',
      pagination: ->n { "#{BEST_BUY_URI}&cp=#{n}" },
      pages: 12
    }.freeze

    WALMART_CONFIG = {
      type: 'json',
      store: 'Walmart',
      base_url: 'https://www.walmart.com',
      item_query: %w[items],
      title_query: %w[title].freeze,
      price_query: %w[primaryOffer offerPrice].freeze,
      url_query: %w[productPageUrl].freeze,
      pagination: ->n { "#{WALMART_URI}&page=#{n}" },
      pages: 13
    }.freeze

    TARGET_CONFIG = {
      type: 'json',
      store: 'Target',
      base_url: 'https://www.target.com',
      item_query: %w[search_response items Item],
      title_query: %w[title].freeze,
      price_query: %w[price current_retail].freeze,
      url_query: %w[url].freeze,
      pagination: ->n { "#{TARGET_URI}&count=24&offset=#{24 * (n - 1)}" },
      pages: 3
    }.freeze

    OVERSTOCK_CONFIG = {
      type: 'json',
      store: 'Overstock',
      base_url: 'https://www.overstock.com',
      item_query: %w[products],
      title_query: %w[name].freeze,
      price_query: %w[pricing current priceBreakdown price].freeze,
      url_query: %w[urls productPage].freeze,
      pagination: ->n { "#{OVERSTOCK_URI}&page=#{n}" },
      pages: 4
    }.freeze

    COSTCO_CONFIG = {
      type: 'html',
      store: 'Costco',
      base_url: 'https://www.costco.com',
      item_query: '.product',
      title_query: '.description a',
      price_query: '.caption .price',
      url_query: '.description a @href',
      pagination: ->_ { COSTCO_URI },
      pages: 1
    }.freeze

    AMAZON_CONFIG = {
      type: 'html',
      store: 'Amazon',
      base_url: 'https://www.amazon.com',
      item_query: '.s-result-item',
      title_query: 'img @alt',
      price_query: '.a-offscreen',
      url_query: 'a @href',
      pagination: ->n { "#{AMAZON_URI}&page=#{n}" },
      pages: 20
    }.freeze

    FRYS_CONFIG = {
      type: 'html',
      store: 'Frys',
      base_url: 'https://www.frys.com',
      item_query: '.product',
      title_query: '.productDescp a',
      price_query: '.toGridPriceHeight ul li .red_txt',
      url_query: '.productDescp a @href',
      pagination: ->n { "#{FRYS_URI}?page=#{n}&start=#{20 * (n - 1)}&rows=20" },
      pages: 20
    }.freeze

    NEWEGG_CONFIG = {
      type: 'html',
      store: 'Newegg',
      base_url: 'https://www.newegg.com',
      item_query: '.item-container',
      title_query: '.item-info .item-title',
      price_query: '.item-action .price-current',
      url_query: '.item-info a.item-title @href',
      pagination: ->n { "#{NEWEGG_URI}&page=#{n}" },
      pages: 29
    }.freeze

    ALL_CONFIGS = [
      BEST_BUY_CONFIG,
      COSTCO_CONFIG,
      AMAZON_CONFIG,
      WALMART_CONFIG,
      FRYS_CONFIG,
      NEWEGG_CONFIG,
      TARGET_CONFIG,
      OVERSTOCK_CONFIG
    ].freeze
  end
end
