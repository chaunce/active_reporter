# frozen_string_literal: true

module ActiveReporter
  module Serializer
    class Highcharts < Table
      def colors
        ["#7cb5ec", "#434348", "#90ed7d", "#f7a35c", "#8085e9", "#f15c80", "#e4d354", "#2b908f", "#f45b5b", "#91e8e1"]
      end

      def color_hash
        # ensure we consistently assign the same color to the same dimension-
        # value pair
        @color_hash ||= Hash.new do |h, key|
          color_cycle = colors.cycle
          h[key] = Hash.new do |hh, value|
            hh[value] = color_cycle.next
          end
        end
      end

      def color_for(dimension, value)
        # override this if the values of a particular dimension can take on
        # meaningful colors
        color_hash[dimension.name][value]
      end

      def series
        case report.groupers.count
        when 3
          dim1, dim2, dim3 = report.groupers
          report.data.flat_map.with_index do |d3, i|
            d3[:values].flat_map do |d2|
              report.all_aggregators.keys.map do |aggregator|
                name = series_name(human_dimension_value_label(dim2, d2[:key]), aggregator)
                {
                  stack: human_dimension_value_label(dim3, d3[:key]),
                  name: name,
                  (i == 0 ? :id : :linkedTo) => name,
                  color: color_for(dim2, d2[:key]),
                  data: d2[:values].map do |d1|
                    {
                      y: aggregator_value(d1, aggregator).to_f,
                      tooltip: tooltip_for({ dim1 => d1, dim2 => d2, dim3 => d3 }, aggregator),
                      filters: filters_for(dim1 => d1, dim2 => d2, dim3 => d3)
                    }
                  end
                }
              end
            end
          end
        when 2
          dim1, dim2 = report.groupers
          report.data.flat_map do |d2|
            report.all_aggregators.keys.map do |aggregator|
              {
                name: series_name(human_dimension_value_label(dim2, d2[:key]), aggregator),
                color: color_for(dim2, d2[:key]),
                data: d2[:values].map do |d1|
                  {
                    y: aggregator_value(d1, aggregator).to_f,
                    tooltip: tooltip_for({ dim1 => d1, dim2 => d2 }, aggregator),
                    filters: filters_for(dim1 => d1, dim2 => d2)
                  }
                end
              }
            end
          end
        when 1
          dim1 = report.groupers.first
          report.all_aggregators.map do |aggregator, aggregator_axis|
            {
              name: human_aggregator_label(aggregator => aggregator_axis),
              data: report.data.map do |d1|
                {
                  y: aggregator_value(d1, aggregator).to_f,
                  tooltip: tooltip_for({ dim1 => d1 }, aggregator),
                  filters: filters_for(dim1 => d1)
                }
              end
            }
          end
        else
          raise ActiveReporter::InvalidParamsError, "report must have <= 3 groupers"
        end
      end

      # The leaf of report.data is { key: grouper_value, values: [{ key:
      # aggregator, value: y }] }, so pull the requested aggregator's value out.
      def aggregator_value(group, aggregator)
        entry = Array(group[:values]).detect { |v| v[:key] == aggregator.to_s }
        entry && entry[:value]
      end

      # When a chart plots more than one aggregator we emit a series per
      # aggregator, so disambiguate the series name; for a single aggregator the
      # name stays as just the grouper value (preserving the prior behavior).
      def series_name(base, aggregator)
        return base if report.all_aggregators.size <= 1

        "#{base} (#{human_aggregator_label(aggregator => report.all_aggregators[aggregator])})"
      end

      def tooltip_for(xes, aggregator)
        lines = []
        xes.each do |dim, d|
          lines << [
            human_dimension_label(dim),
            human_dimension_value_label(dim, d[:key])
          ]
        end
        lines << [
          human_aggregator_label(aggregator => report.all_aggregators[aggregator]),
          human_aggregator_value_label({ aggregator => report.all_aggregators[aggregator] }, aggregator_value(xes[report.groupers.first], aggregator))
        ]
        lines.map { |k, v| "<b>#{k}:</b> #{v}" }.join("<br/>")
      end

      def filters_for(xes)
        xes.each_with_object({}) do |(dim, d), h|
          h[dim.name] = d[:key]
        end
      end

      def categories
        dimension = report.groupers.first
        dimension.group_values.map do |value|
          human_dimension_value_label(dimension, value)
        end
      end

      def chart_title
        axis_summary
      end

      def chart_subtitle
        filter_summary
      end

      def x_axis_title
        human_dimension_label(report.groupers.first)
      end

      def y_axis_title
        human_aggregator_label(report.all_aggregators)
      end

      def highcharts_options
        {
          chart: {
            type: "column"
          },
          colors: colors,
          title: {
            text: chart_title
          },
          subtitle: {
            text: chart_subtitle
          },
          series: series,
          xAxis: {
            categories: categories,
            title: {
              text: x_axis_title
            }
          },
          yAxis: {
            allowDecimals: true,
            title: {
              text: y_axis_title
            },
            stackLabels: {
              enabled: report.groupers.length >= 3,
              format: "{stack}",
              rotation: -45,
              textAlign: "left"
            }
          },
          legend: {
            enabled: report.groupers.length >= 2
          },
          tooltip: {},
          plotOptions: {
            series: {
              events: {}
            },
            column: {
              stacking: ("normal" if report.groupers.length >= 2)
            }
          }
        }
      end
    end
  end
end
