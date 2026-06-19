# frozen_string_literal: true

# Compares report data structurally while treating numeric values as equal when
# they're within a small tolerance. This keeps the acceptance expectations
# adapter-agnostic: Postgres returns AVG() as BigDecimal, SQLite as Float, and
# MySQL as a DECIMAL truncated to 4 decimal places. Rather than rounding the
# expected data to paper over those differences, we compare numbers by value.
#
#   expect(report.data).to match_report_data(expected)
#
RSpec::Matchers.define :match_report_data do |expected|
  # Max absolute difference allowed between two numbers. MySQL's AVG() truncates
  # to 4 decimals (~5e-5 error), so anything looser than that is plenty tight to
  # still catch real aggregation bugs (which differ by whole units here).
  tolerance = 1e-3

  as_number = lambda do |value|
    case value
    when Numeric then value.to_f
    when String  then Float(value) rescue nil # non-numeric strings (names, dates) -> nil
    end
  end

  deep_match = nil
  deep_match = lambda do |exp, act|
    exp_num = as_number.call(exp)
    act_num = as_number.call(act)
    next (exp_num - act_num).abs <= tolerance if exp_num && act_num

    case exp
    when Array
      act.is_a?(Array) && exp.size == act.size &&
        exp.each_index.all? { |i| deep_match.call(exp[i], act[i]) }
    when Hash
      act.is_a?(Hash) && exp.keys.sort == act.keys.sort &&
        exp.all? { |k, v| deep_match.call(v, act[k]) }
    else
      exp == act
    end
  end

  match do |actual|
    # Round-trip through JSON so both sides share the same serialized shape
    # (symbol keys -> strings, Time -> ISO8601, BigDecimal -> string, etc.).
    @expected_json = JSON.parse(expected.to_json)
    @actual_json   = JSON.parse(actual.to_json)
    deep_match.call(@expected_json, @actual_json)
  end

  failure_message do
    "expected report data to match within numeric tolerance #{tolerance}\n" \
      "  expected: #{@expected_json.inspect}\n" \
      "       got: #{@actual_json.inspect}"
  end
end
