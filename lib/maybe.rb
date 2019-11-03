# frozen_string_literal: true

# Represent a possibly present value
module TvPrices
  class Maybe
    class << self
      def nothing
        new(nil)
      end

      def just(val)
        new(val)
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
end
