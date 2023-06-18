# sqlite uses Float instead of BigDecimal, this extension to Float class ensures the serialized
# objects match the test data in specs.

class Float
  def as_json(options={})
    super&.to_s
  end
end