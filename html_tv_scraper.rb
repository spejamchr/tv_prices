# frozen_string_literal: true

require 'nokogiri'

require './maybe'
require './tv_scraper'
require './get_from_cache_or_web'

def get_html(uri, store, page)
  html = get_from_cache_or_web(uri, store, page) do |options|
    # Have to do this for BestBuy, the Firefox agent wasn't working
    options.merge('User-Agent' => "Ruby/#{RUBY_VERSION}")
  end

  Nokogiri::HTML(html)
end

# Parse TV info from an HTML page
class HtmlTvScraper < TvScraper
  private

  def items(page)
    uri = pagination.call(page)
    html = get_html(uri, store, page)
    html.search(item_query)
  end

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
