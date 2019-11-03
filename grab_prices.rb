# frozen_string_literal: true

# Get dependencies:
#
#   gem install nokogiri
#   gem install parallel

require 'csv'
require 'Parallel'
require 'fileutils'

require './maybe'
require './tv_scraper'
require './html_tv_scraper'
require './json_tv_scraper'
require './config'

def just_number(string)
  string.to_s.gsub(/[^\d\.]/, '').to_f
end

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
  File.join(CACHED_DIR, store)
end

def last_updated_file
  File.join(CACHED_DIR, LAST_UPDATED_FILE)
end

Dir.mkdir(HISTORY_DIR) unless Dir.exists?(HISTORY_DIR)

unless Dir.exists?(CACHED_DIR)
  Dir.mkdir(CACHED_DIR)
  File.write(last_updated_file, Time.now.to_i)
end

Parallel.each(ALL_CONFIGS.map { |cfg| cfg.fetch(:store) }) do |store|
  Dir.mkdir(store_dir(store)) unless Dir.exist?(store_dir(store))
end

results =
  Parallel
  .flat_map(ALL_CONFIGS) { |cfg| TvScraper.all_results(cfg) }
  .sort_by { |i| sortable_array(i) }
  .group_by { |i| i[:url] }
  .values
  .map(&:first)

history_filename = [File.read(last_updated_file), CSV_NAME].join('_')
history_path = File.join(HISTORY_DIR, history_filename)

CSV.open(history_path, 'wb') do |csv|
  csv << HEADERS
  results.each { |attrs| csv << HEADERS.map { |key| attrs[key] } }
end

# The history of prices is kept twice: Once in the HISTORY_DIR, and once in the
# git history of the CSV_NAME file.
FileUtils.cp(history_path, CSV_NAME)
