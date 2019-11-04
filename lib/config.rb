# frozen_string_literal: true

require 'yaml'

# Recursively freeze self if it's Enumerable
module Kernel
  alias deep_freeze freeze
  alias deep_frozen? frozen?
end

module Enumerable
  def deep_freeze
    return if deep_frozen?

    each(&:deep_freeze)
    @deep_frozen = true
    freeze
  end

  def deep_frozen?
    !!@deep_frozen
  end
end

# Set the configuration for various parts of the scraper
#
# Most of it is loaded from the YAML file at: `config/application.yml`
module TvPrices
  module Config
    class << self
      private
      def fill_vars!(string, store)
        string.gsub!(/{(\w+)}/) { store.fetch($1.to_sym).to_s }
      end

      def pagination_lambda(store)
        pagination = store.fetch(:pagination)

        if pagination.include?('{&offset}') && !store.has_key?(:per)
          raise "#{store.fetch(:store)} config requires :per"
        end

        lambda do |page|
          pagination
            .gsub('{&page}', page.to_s)
            .gsub('{&offset}') { (store.fetch(:per) * (page - 1)).to_s }
        end
      end

      def load_store(store)
        store.transform_keys!(&:to_sym)
        fill_vars!(store.fetch(:search_url), store)
        fill_vars!(store.fetch(:pagination), store)
        store[:pagination] = pagination_lambda(store)

        store
      end
    end

    # Whether to output debug-level logging statements
    DEBUG = ARGV.include?('--debug')

    config = YAML.load_file('config/application.yml')

    CACHED_DIR = config.fetch('CACHED_DIR').deep_freeze
    LAST_UPDATED_FILE = config.fetch('LAST_UPDATED_FILE').deep_freeze
    HISTORY_DIR = config.fetch('HISTORY_DIR').deep_freeze
    CSV_NAME = config.fetch('CSV_NAME').deep_freeze
    HEADERS = config.fetch('HEADERS').map(&:to_sym).deep_freeze
    URI_OPTIONS = config.fetch('URI_OPTIONS').deep_freeze

    ALL_CONFIGS =
      config.fetch('ALL_CONFIGS').map { |store| load_store(store) }.deep_freeze
  end
end
