# frozen_string_literal: true

# Get dependencies:
#
#   gem install httparty
#   gem install nokogiri
#   gem install parallel

require 'HTTParty'
require 'open-uri'
require 'nokogiri'
require 'Parallel'

DEBUG = false

CACHED_DIR = 'cached_pages'

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
  # Overstock rejects my requests with a regular Ruby User-Agent. Use Firefox.
  'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; ' \
    'rv:68.0) Gecko/20100101 Firefox/68.0',
  'From' => 'spensterc@yahoo.com',
  'Referer' => 'http://www.ruby-lang.org/'
}.freeze

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

BEST_BUY_CONFIG = {
  store: 'Best Buy',
  base_url: 'https://www.bestbuy.com',
  item_query: '.sku-item',
  title_query: '.information .sku-title a',
  price_query: '.price-block .priceView-hero-price.priceView-customer-price',
  url_query: '.information .sku-title a @href'
}.freeze

WALMART_CONFIG = {
  store: 'Walmart',
  base_url: 'https://www.walmart.com',
  item_query: %w[items],
  title_query: %w[title].freeze,
  price_query: %w[primaryOffer offerPrice].freeze,
  url_query: %w[productPageUrl].freeze
}.freeze

TARGET_CONFIG = {
  store: 'Target',
  base_url: 'https://www.target.com',
  item_query: %w[search_response items Item],
  title_query: %w[title].freeze,
  price_query: %w[price current_retail].freeze,
  url_query: %w[url].freeze
}.freeze

OVERSTOCK_CONFIG = {
  store: 'Overstock',
  base_url: 'https://www.overstock.com',
  item_query: %w[products],
  title_query: %w[name].freeze,
  price_query: %w[pricing current priceBreakdown price].freeze,
  url_query: %w[urls productPage].freeze
}.freeze

COSTCO_CONFIG = {
  store: 'Costco',
  base_url: 'https://www.costco.com',
  item_query: '.product',
  title_query: '.description a',
  price_query: '.caption .price',
  url_query: '.description a @href'
}.freeze

AMAZON_CONFIG = {
  store: 'Amazon',
  base_url: 'https://www.amazon.com',
  item_query: '.s-result-item',
  title_query: 'img @alt',
  price_query: '.a-offscreen',
  url_query: 'a @href'
}.freeze

FRYS_CONFIG = {
  store: 'Frys',
  base_url: 'https://www.frys.com',
  item_query: '.product',
  title_query: '.productDescp a',
  price_query: '.toGridPriceHeight ul li .red_txt',
  url_query: '.productDescp a @href'
}.freeze

NEWEGG_CONFIG = {
  store: 'Newegg',
  base_url: 'https://www.newegg.com',
  item_query: '.item-container',
  title_query: '.item-info .item-title',
  price_query: '.item-action .price-current',
  url_query: '.item-info a.item-title @href'
}.freeze

# Represent a possibly present value
class Maybe
  def self.nothing
    new(nil)
  end

  def self.just(val)
    new(val)
  end

  def initialize(val)
    @val = val.nil? ? { kind: :nothing } : { kind: :just, val: val }
  end

  def map
    thing = just? ? yield(val[:val]) : self
    thing.is_a?(Maybe) ? thing : Maybe.new(thing)
  end

  def or_else
    thing = just? ? self : yield
    thing.is_a?(Maybe) ? thing : Maybe.new(thing)
  end

  def effect
    just? && yield(val[:val])
    self
  end

  def or_effect
    just? || yield
    self
  end

  def assign(name)
    return self unless just?
    return self.class.nothing unless val[:val].is_a?(Hash)

    other = yield(val[:val])
    other = other.is_a?(Maybe) ? other : Maybe.new(other)
    other.map { |ov| val[:val].merge(name => ov) }
  end

  def get_or_else(other)
    just? ? val[:val] : other
  end

  private

  attr_reader :val

  def just?
    val[:kind] == :just
  end
end

def map_maybe(maybes)
  return to_enum(:map_maybe, maybes) unless block_given?

  results = []
  maybes.each do |maybe|
    maybe.effect { |val| results << yield(val) }
  end
  results
end

def only_justs(maybes)
  map_maybe(maybes, &:itself)
end

# Utility methods for parsing TV string titles
module ParseTitle
  BRANDS = %w[
    ATYME AVERA AXESS CROWN ELEMENT FURRION GPX HISENSE HITACHI INSIGNIA JENSEN
    JVC KC LG MAGNAVOX NAXA PANASONIC PHILIPS PHILLIPS POLAROID PROSCAN PYLE
    RCA SAMSUNG SANYO SCEPTRE SEIKI SHARP SHARP SILO SKYWORTH SKYWORTH SONY
    SPELER SUNBRITE SUNBRITETV SUPERSONIC SÉURA TCL TOSHIBA VIEWSONIC VIZIO
    WESTINGHOUSE
  ].freeze

  private

  def find_match(title, regex)
    Maybe.new(title.match(regex)).map(&:to_s)
  end

  def brand_decoder(title)
    title = title.gsub(/[^a-z ]/i, '').upcase # Remove TM symbols

    Maybe
      .new((title.split(' ') & BRANDS).first)
      .or_effect { puts "Could not decode brand: #{title}" if DEBUG }
  end

  def size_decoder(title)
    # Explude any TVs in the single-digit size. Too small, and too easily
    # confused with other numbers (such as soundbar sizes).
    nums = /\d{2,}(\.\d{0,2})?/

    Maybe
      .nothing
      .or_else { find_match(title, /\b#{nums}["”']/) }
      .or_else { find_match(title, /\b#{nums}.?inch\b/i) }
      .or_else { find_match(title, /\b#{nums}.?in\b/i) }
      .or_else { find_match(title, /\b#{nums}.?Class/) }
      .map { |s| s.match(/#{nums}/).to_s }
      .or_effect { puts "Could not decode size: #{title}" if DEBUG }
  end

  def tech_decoder(title)
    find_match(title, /\b[OQUX]?LED\b/i)
      .or_else { find_match(title, /\bquantum\b/i).map { 'QLED' } }
      .or_effect { puts "Could not decode tech: #{title}" if DEBUG }
      .get_or_else('LED')
      .upcase
  end

  def k_to_p(nk_res)
    {
      '1k' => '1080p',
      '4k' => '2160p',
      '5k' => '2160p',
      '8k' => '4320p'
    }.fetch(nk_res.downcase)
  end

  def explicit_res_matcher(title)
    find_match(title, /\b\d+p\b/i)
  end

  def nk_matcher(title)
    find_match(title, /\b\dk\b/i)
      .map { |nk| k_to_p(nk) }
  end

  def uhd_matcher(title)
    Maybe
      .nothing
      .or_else { find_match(title, /\buhd\b/i).map { '2160p' } }
      .or_else { find_match(title, /\bultra hd\b/i).map { '2160p' } }
  end

  def hd_matcher(title)
    Maybe
      .nothing
      .or_else { find_match(title, /\bhd\b/i).map { '1080p' } }
      .or_else { find_match(title, /\bhdtv\b/i).map { '1080p' } }
      .or_else { find_match(title, /\bfhd\b/i).map { '1080p' } }
  end

  def nxn_matcher(title)
    find_match(title, /\d+.?x.?\d+/i)
      .map { |s| "#{s.scan(/\d+/).last}p" }
  end

  def resolution_decoder(title)
    Maybe
      .nothing
      .or_else { explicit_res_matcher(title) }
      .or_else { nk_matcher(title) }
      .or_else { uhd_matcher(title) }
      .or_else { hd_matcher(title) }
      .or_else { nxn_matcher(title) }
      .map(&:downcase)
      .or_effect { puts "Could not decode resolution: #{title}" if DEBUG }
  end

  def basic_attributes(title)
    Maybe
      .just(title: title)
      .assign(:size) { size_decoder(title) }
      .assign(:resolution) { resolution_decoder(title) }
      .assign(:tech) { tech_decoder(title) }
      .assign(:brand) { brand_decoder(title) }
  end
end

# Parent of all scrapers
#
# Scrapers must define private methods which recieve a TV list item:
#   - item_title
#   - item_price
#   - item_ref
#
# And should define a public `results` method
#
class ScraperBase
  include ParseTitle

  def initialize(**args)
    @args = args
    @store = args.fetch(:store)
    @base_url = args.fetch(:base_url)
    @item_query = args.fetch(:item_query)
    @title_query = args.fetch(:title_query)
    @price_query = args.fetch(:price_query)
    @url_query = args.fetch(:url_query)
  end

  private

  attr_reader(
    :args,
    :store,
    :base_url,
    :item_query,
    :title_query,
    :price_query,
    :url_query
  )

  def fetch_results(items, page)
    only_justs(items.map { |i| attributes(i) })
      .map { |attrs| attrs.merge(page: page) }
  end

  def attributes(item)
    basic_attributes(item_title(item))
      .assign(:store) { store }
      .assign(:price) { item_price(item) }
      .assign(:url) { item_url(item) }
  end

  def item_url_from_ref(ref)
    url_from_ref(ref)
    'https://' + url_from_ref(ref).select(:host, :path).join
  end

  def url_from_ref(ref)
    uri = URI.parse(ref.gsub(';', '?'))
    uri = uri.absolute? ? uri : URI.parse(base_url) + uri
    uri.normalize
  end

  def item_url(item)
    item_ref(item).map { |ref| item_url_from_ref(ref) }
  end
end

# Parse TV info from an HTML page
class HtmlTvScraper < ScraperBase
  def results(html, page)
    fetch_results(html.search(item_query), page)
  end

  private

  def text_at(doc, css_path)
    Maybe
      .new(doc.at(css_path))
      .map(&:text)
      .or_effect { puts "Could not find text_at: #{css_path}" if DEBUG }
  end

  def safe_encode(string)
    string.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
  end

  def item_title(item)
    text_at(item, title_query)
      .map { |s| safe_encode(s) }
      .get_or_else('')
      .gsub(/\s+/, ' ')
  end

  def item_ref(item)
    text_at(item, url_query)
  end

  def item_price(item)
    text_at(item, price_query)
      .map { |s| s.match(/\$[\d\,]+(\.\d\d)?/)&.to_s }
      .or_effect { item_url(item).effect { |a| p a if DEBUG } }
  end
end

# Parse TV info from a list of JSON objects
class JsonScraper < ScraperBase
  def results(json, page)
    fetch_results(fetch(json, item_query).get_or_else([]), page)
  end

  private

  def fetch(item, query)
    Maybe
      .new(item.dig(*query))
      .or_effect { puts "Could not fetch field: #{query}" if DEBUG }
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
      .or_effect { item_url(item).effect { |a| p a if DEBUG } }
  end
end

def save_url_to(uri, path)
  puts "Fetching web page at #{uri}"
  # Have to do this for BestBuy, the Firefox agent wasn't working
  options = URI_OPTIONS.merge('User-Agent' => "Ruby/#{RUBY_VERSION}")
  URI.parse(uri).open(options) { |f| File.write(path, f.read) }
end

def get_doc(uri, store, page)
  store_dir = File.join(CACHED_DIR, store)
  path = File.join(store_dir, "page_#{page}.html")

  Dir.mkdir(store_dir) unless Dir.exist?(store_dir)
  save_url_to(uri, path) unless File.readable?(path)

  Nokogiri::HTML(File.read(path))
end

def get_json(uri, store, page)
  store_dir = File.join(CACHED_DIR, store)
  path = File.join(store_dir, "page_#{page}.json")

  Dir.mkdir(store_dir) unless Dir.exist?(store_dir)

  unless File.readable?(path)
    options = URI_OPTIONS.merge('Accept' => 'application/json')
    URI.parse(uri).open(options) { |f| File.write(path, f.read) }
  end

  JSON.parse(File.read(path))
end

def best_buy_results(uri)
  scraper = HtmlTvScraper.new(BEST_BUY_CONFIG)
  Parallel.map(1..12) do |page|
    scraper.results(get_doc("#{uri}&cp=#{page}", 'BestBuy', page), page)
  end.flatten
end

def costco_results(uri)
  HtmlTvScraper
    .new(COSTCO_CONFIG)
    .results(get_doc(uri, 'Costco', 1), 1)
    .flatten
end

def walmart_results(uri)
  scraper = JsonScraper.new(WALMART_CONFIG)
  Parallel.map(1..13) do |page|
    scraper.results(
      get_json("#{uri}&page=#{page}", 'Walmart', page),
      page
    )
  end.flatten
end

def target_results(uri)
  per = 24
  scraper = JsonScraper.new(TARGET_CONFIG)
  Parallel.map(1..3) do |page|
    start = per * (page - 1)
    scraper.results(
      get_json("#{uri}&count=#{per}&offset=#{start}", 'Target', page),
      page
    )
  end.flatten
end

def overstock_results(uri)
  scraper = JsonScraper.new(OVERSTOCK_CONFIG)
  Parallel.map(1..4) do |page|
    scraper.results(
      get_json("#{uri}&page=#{page}", 'Overstock', page),
      page
    )
  end.flatten
end

def amazon_results(uri)
  scraper = HtmlTvScraper.new(AMAZON_CONFIG)
  Parallel.map(1..20) do |page|
    page_uri = "#{uri}&page=#{page}"

    scraper.results(get_doc(page_uri, 'Amazon', page), page)
  end.flatten
end

def frys_results(uri)
  per = 20
  scraper = HtmlTvScraper.new(FRYS_CONFIG)
  Parallel.map(1..20) do |page|
    start = per * (page - 1)
    page_uri = "#{uri}?page=#{page}&start=#{start}&rows=#{per}"

    scraper.results(get_doc(page_uri, 'Frys', page), page)
  end.flatten
end

def newegg_results(uri)
  scraper = HtmlTvScraper.new(NEWEGG_CONFIG)
  Parallel.map(1..29) do |page|
    scraper.results(get_doc("#{uri}&page=#{page}", 'Newegg', page), page)
  end.flatten
end

def just_number(string)
  string.to_s.gsub(/[^\d\.]/, '').to_f
end

def sortable_array(hash)
  [
    just_number(hash[:size]),
    hash[:tech],
    just_number(hash[:resolution]),
    just_number(hash[:price]),
    *hash.values_at(:brand, :store, :page, :url)
  ]
end

Dir.mkdir(CACHED_DIR) unless Dir.exist?(CACHED_DIR)

tasks = [
  -> { best_buy_results(BEST_BUY_URI) },
  -> { costco_results(COSTCO_URI) },
  -> { amazon_results(AMAZON_URI) },
  -> { walmart_results(WALMART_URI) },
  -> { frys_results(FRYS_URI) },
  -> { newegg_results(NEWEGG_URI) },
  -> { target_results(TARGET_URI) },
  -> { overstock_results(OVERSTOCK_URI) }
]

results =
  Parallel
  .flat_map(tasks, &:call)
  .sort_by { |i| sortable_array(i) }
  .group_by { |i| i[:url] }
  .values
  .map(&:first)

CSV.open('scraped_televisions.csv', 'wb') do |csv|
  csv << HEADERS
  results.each { |attrs| csv << HEADERS.map { |key| attrs[key] } }
end
