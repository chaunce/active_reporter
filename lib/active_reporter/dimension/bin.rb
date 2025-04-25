require "active_reporter/dimension/base"

module ActiveReporter
  module Dimension
    class Bin < Base
      MAX_BINS = 2_000

      def max_bins
        self.class::MAX_BINS
      end

      # report values are greater than or equal to min, grouped by bin_width
      def min
        @min ||= filter_min || report.records.minimum(expression)
      end
      alias bin_start min

      # report values are less than max, grouped by bin_width
      def max
        @max ||= filter_max || report.records.maximum(expression)
      end

      def bin_end
        @bin_end ||= if max.blank? || min.blank? || min > max
          nil
        else
          bin_edge = bin_start + bin_width

          loop do
            break if bin_edge >= max
            bin_edge += bin_width
          end

          bin_edge += bin_width unless filter_values_for(:max).present? # # # figure out why we need this??

          bin_edge
        end
      end

      def filter_min
        filter_values_for(:min).min
      end

      def filter_max
        filter_values_for(:max).max
      end

      def domain
        min.nil? || max.nil? ? 0 : (max - min)
      end

      def group_values
        @group_values ||= to_bins(array_param(:bins).presence || autopopulate_bins)
      end

      def filter_values
        @filter_values ||= to_bins(super)
      end

      def filter(relation)
        filter_values.filter(relation, expression)
      end

      def group(relation)
        group_values.group(relation, expression, sql_value_name)
      end

      def validate_params!
        super

        if params.key?(:bin_count)
          invalid_param!(:bin_count, "must be numeric") unless ActiveReporter.numeric?(params[:bin_count])
          invalid_param!(:bin_count, "must be greater than 0") unless params[:bin_count].to_i > 0
          invalid_param!(:bin_count, "must be less than #{max_bins}") unless params[:bin_count].to_i <= max_bins
        end

        if array_param(:bins).present?
          invalid_param!(:bins, "must be hashes with min/max keys and valid values, or nil") unless group_values.all?(&:valid?)
        end

        if array_param(:only).present?
          invalid_param!(:only, "must be hashes with min/max keys and valid values, or nil") unless filter_values.all?(&:valid?)
        end
      end

      private

      def filter_values_for(key)
        filter_values.map { |filter_value| filter_value.send(key) }.compact
      end

      def table
        self.class.const_get(:Table)
      end

      def set
        self.class.const_get(:Set)
      end

      def to_bins(bins)
        table.new(bins.map(&method(:to_bin)))
      end

      def to_bin(bin)
        set.from_hash(bin)
      end

      def sanitize_sql_value(value)
        set.from_sql(value)
      end

      def data_contains_nil?
        report.records.where("#{expression} IS NULL").exists?
      end

      def autopopulate_bins
        return [] if bin_start.blank? || bin_end.blank?

        bin_count = [((bin_end - bin_start)/(bin_width)).to_i, 1].max
        invalid_param!(:bin_width, "is too small for the domain; would generate #{bin_count.to_i} bins") if bin_count > max_bins

        bins = bin_count.times.map { |i| { min: (bin_start + (bin_width*i)), max: (bin_start + (bin_width*i.next)) } }

        bins.reverse! if sort_desc?
        ( nulls_last? ? bins.push(nil) : bins.unshift(nil) ) if data_contains_nil?

        bins
      end
    end
  end
end
