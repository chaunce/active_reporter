# Changelog

This is a working draft of changes since the last release (v0.8.1). It is not
yet organized/finalized for publishing — it exists to capture everything,
especially breaking changes, while the work is in progress.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## 1.0.1

### ⚠️ Breaking changes

- **`Serializer::Highcharts#series` now emits one series per aggregator.**
  Previously the serializer assumed a single y-value per group and (due to a
  bug) emitted `y: 0.0` for every point. Charts with multiple aggregators now
  produce a distinct series per aggregator, series names are suffixed with the
  aggregator label when more than one aggregator is present, and y-values are
  populated correctly. `#tooltip_for` also changed signature (it now takes the
  aggregator as a second argument). Any code consuming the Highcharts series
  structure directly will need to be updated.

- **`autoreport_on` now generates more specific dimension types.**
  - Enum-backed columns (e.g. a Rails `enum :status`) are stored as integers, so
    autoreport previously classified them as `Dimension::Number`. They are now
    detected via the model's `defined_enums` and declared as `Dimension::Enum`.
  - Boolean columns were previously classified as `Dimension::Category`; they are
    now declared as the new `Dimension::Boolean`.
  Reports relying on the old autoreport classification of enum or boolean columns
  will behave differently.

- **`Report#params` now strips blank values, not just nils.**
  Parameter compaction switched from `DeeplyEnumerable::Hash.deep_compact` to
  `deep_compact_blank`, so blank values (empty strings, empty arrays/hashes) are
  now removed in addition to `nil`s. Reports that depended on blank params being
  preserved may see different behavior.

- **Dimension/aggregator option accessor renamed `opts` → `options`.** The
  instance accessor (`dimension.opts` / `aggregator.opts`) and the registration
  hash key (`report_model.dimensions[:x][:opts]`) are now `options`. Affects code
  that subclasses a dimension/aggregator or introspects the registration hash.

- **`deeply_enumerable` dependency bumped to `~> 2.0`** (was `>= 0.9.3, < 2.0`).
  This is a major-version bump of a runtime dependency.

- **`Dimension::Base#enum?` and `Aggregator::Base#enum?` now perform real enum
  detection** instead of always returning `false`. They return
  `Hash(model&.defined_enums).include?(attribute.to_s)`. Subclasses/overrides
  that relied on the hardcoded `false` will see different results.

- **`Tracker::Value#track` now returns the prior period's value.** The previous
  implementation had inverted logic (`... if prior_row.nil?`) and never returned
  a usable value. Any reports using a value tracker will now produce actual
  tracked values.

### Added

- **`Dimension::Boolean`** (`boolean_dimension`) — a Category-based dimension for
  boolean columns. It casts filter values to real booleans and normalizes grouped
  SQL values to `true`/`false`/`nil` consistently across adapters. `autoreport_on`
  declares it automatically for boolean columns.
- Ruby 3.3–4.0 and Rails 7.1–8.1 compatibility (CI matrix covers Ruby 3.3/3.4/4.0
  against PostgreSQL, MySQL, and SQLite). `required_ruby_version` is now `>= 3.3`.

### Fixed

- **`Serializer::Csv#save`** previously raised `NoMethodError` (it referenced a
  nonexistent `data` method); it now writes `csv_text`.
- **`Serializer::FormField`** raised `NameError` for bin-type dimension fields
  (referenced the nonexistent `Dimension::Set`; now uses `Dimension::Bin`), and
  `#aggregator_options` passed a single aggregator to a hash-expecting label
  method. Both are fixed.
- **`Dimension::Category#all_values`** now wraps its `DISTINCT` expression in
  `Arel.sql`, fixing `ActiveRecord::UnknownAttributeReference` on Rails 8.
- **`Dimension::Bin::Set#values_at`** referenced an undefined local (`key`
  instead of the block variable `k`) and never returned correct values.
- **`Report` validation** for calculators/trackers referenced `self.class.aggregator`
  (the DSL registration method, requiring arguments) instead of
  `self.class.aggregators`, which would raise `ArgumentError` instead of adding
  the intended validation error.
- **`Report::Metrics#fields`** raised `NoMethodError` (`Array#merge`); it now uses
  `flatten`.

### Dependencies

- `deeply_enumerable` `~> 2.0` (was `>= 0.9.3, < 2.0`).
- Added `csv` `~> 3.3` as a runtime dependency (CSV was removed from Ruby's
  default gems in 3.4+; required by `Serializer::Csv`).
- Added `ostruct` as a development dependency (removed from default gems in Ruby
  4.0; used by the dimension specs).

### Internal / Development

- Test suite expanded to ~100% line coverage (100% on PostgreSQL; the remainder
  on MySQL/SQLite are PostgreSQL-only SQL paths).
- Test database is created and the schema loaded automatically on boot (no manual
  `rake db:create db:schema:load` step).
- `rake spec:all` runs the suite against all three database adapters.
- The dummy app uses `config.load_defaults 8.1`.
- Enabled `# frozen_string_literal: true` across the gem and added RuboCop
  (rubocop, -performance, -packaging, -rspec) as development dependencies.

### Open / under review

- `Report::Definition#default_report_model` is an unused duplicate of
  `default_model` (currently excluded from coverage); pending a decision to keep
  or remove.
