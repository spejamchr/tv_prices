# frozen_string_literal: true

require 'Parallel'
require 'open-uri'

require './parse_title.rb'

# Parent of all scrapers
#
# Sub-scrapers must end in "TvScraper"
#
# Scrapers must define private methods:
#   - item_title : Receives a TV list item, returns a title string
#   - item_price : Receives a TV list item, returns a string price
#   - item_ref : Receives a TV list item, returns a string url/ref
#   - items : Receives an integer page number, returns an array of items
#
class TvScraper
  include ParseTitle
  @types = {}

  def self.inherited(child_class)
    type = child_class.to_s.chomp(to_s).downcase.to_sym
    @types[type] = child_class
  end

  def self.all_results(config)
    @types.fetch(config.fetch(:type).to_sym).new(config).all_results
  end

  def initialize(**args)
    @args = args
    @store = args.fetch(:store)
    @base_url = args.fetch(:base_url)
    @item_query = args.fetch(:item_query)
    @title_query = args.fetch(:title_query)
    @price_query = args.fetch(:price_query)
    @url_query = args.fetch(:url_query)
    @pagination = args.fetch(:pagination)
    @pages = args.fetch(:pages)
  end

  def all_results
    Parallel.flat_map(1..pages) { |page| fetch_results(page) }
  end

  private

  attr_reader(
    :args,
    :store,
    :base_url,
    :item_query,
    :title_query,
    :price_query,
    :url_query,
    :pagination,
    :pages
  )

  def fetch_results(page)
    only_justs(items(page).map { |i| attributes(i) })
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
