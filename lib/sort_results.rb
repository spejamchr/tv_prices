# frozen_string_literal: true

module TvPrices
  module SortResults
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

      def sort_results(results)
        results
          .sort_by { |i| sortable_array(i) }
          .group_by { |i| i[:url] }
          .values
          .map(&:first)
      end

      def just_number(string)
        string.to_s.gsub(/[^\d\.]/, '').to_f
      end
    end
  end
end
