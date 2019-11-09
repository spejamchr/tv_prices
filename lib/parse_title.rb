# frozen_string_literal: true

require_relative 'maybe'

# Utility methods for parsing TV string titles
module TvPrices
  module ParseTitle
    BRANDS = %w[
      ATYME AVERA AXESS CROWN ELEMENT FURRION GPX HISENSE HITACHI INSIGNIA
      JENSEN JVC KC LG MAGNAVOX NAXA PANASONIC PHILIPS PHILLIPS POLAROID
      PROSCAN PYLE RCA SAMSUNG SANYO SCEPTRE SEIKI SHARP SHARP SILO SKYWORTH
      SONY SPELER SUNBRITE SUNBRITETV SUPERSONIC SÉURA TCL TOSHIBA VIEWSONIC
      VIZIO WESTINGHOUSE
    ].freeze

    private

    def find_match(title, regex)
      Maybe.new(title.match(regex)).map(&:to_s)
    end

    def brand_decoder(title)
      title = title.gsub(/[^a-z ]/i, '').upcase # Remove TM symbols

      Maybe
        .new((title.split(' ') & BRANDS).first)
        .or_effect { puts "Could not decode brand: #{title}" if Config::DEBUG }
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
        .or_effect { puts "Could not decode size: #{title}" if Config::DEBUG }
    end

    def tech_decoder(title)
      find_match(title, /\b[OQUX]?LED\b/i)
        .or_else { find_match(title, /\bquantum\b/i).map { 'QLED' } }
        .or_effect { puts "Could not decode tech: #{title}" if Config::DEBUG }
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
      find_match(title, /(?<!-)\b\dk\b(?!-)/i)
        .map { |nk| k_to_p(nk) }
    end

    def uhd_matcher(title)
      Maybe
        .nothing
        .or_else { find_match(title, /\buhd\b/i).map { '2160p' } }
        .or_else { find_match(title, /\bultra hd\b/i).map { '2160p' } }
        .or_else { find_match(title, /\bultra hdtv\b/i).map { '2160p' } }
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
        .or_effect { puts "Could not decode resolution: #{title}" if Config::DEBUG }
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
end
