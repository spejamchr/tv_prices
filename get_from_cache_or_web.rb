# frozen_string_literal: true

require 'open-uri'

URI_OPTIONS = {
  # Overstock rejects my requests with a regular Ruby User-Agent. Use Firefox.
  'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; ' \
    'rv:68.0) Gecko/20100101 Firefox/68.0',
  'From' => 'spensterc@yahoo.com',
  'Referer' => 'http://www.ruby-lang.org/'
}.freeze

def get_from_cache_or_web(uri, store, page)
  path = File.join(store_dir(store), "page_#{page}.html")

  unless File.readable?(path)
    puts "Fetching web page at #{uri}"
    options = block_given? ? yield(URI_OPTIONS) : URI_OPTIONS
    URI.parse(uri).open(options) { |f| File.write(path, f.read) }
  end

  File.read(path)
end
