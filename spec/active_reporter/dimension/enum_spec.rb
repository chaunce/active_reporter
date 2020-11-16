require 'spec_helper'

describe ActiveReporter::Dimension::Enum do
  let(:report_model) { :post }
  let(:report) do
    OpenStruct.new(
      params: { dimensions: { groupers: [:status] } }, 
      groupers: [:status, :category], 
      raw_data: {
        ['published', 'post_count'] => 5, ['published', 'post_total'] => 500.00, ['published', 'post_average'] => 100.00,
        ['archived', 'post_count'] => 7, ['archived', 'post_total'] => 530.25, ['archived', 'post_average'] => 75.75,
      },
    )
  end

  let(:status_dimension) do
    dimension = ActiveReporter::Dimension::Enum.new(:status, report, { model: report_model })
    report.groupers[report.groupers.index(:status)] = dimension if report.groupers.include?(:status)
    dimension
  end

  # def status_dimension(report)
  #   described_class.new(:status, report, model: :posts, attribute: :status)
  # end

  # def author_dimension(report)
  #   described_class.new(:author, report, model: :authors, attribute: :name, relation: ->(r) { r.joins(
  #     "LEFT OUTER JOIN authors ON authors.id = posts.author_id") })
  # end

  describe '#group_values' do
    # it 'echoes filter_values if filtering' do
    #   dimension = status_dimension(OpenStruct.new(params: {
    #     groupers: [:status]
    #   }))
    #   expect(dimension.group_values).to eq [nil, 'draft', 'unpublished', 'published', 'archived']
    # end


    it 'determines #filtering?' do
      expect(status_dimension).not_to be_filtering
      expect(status_dimension.group_values).to match %w(published archived)
    end
  end

  # describe '#all_values' do
  #   it 'returns model enum values' do
  #     dimension = author_dimension(OpenStruct.new(params: {
  #       dimensions: { author: { only: [nil, 'draft', 'unpublished', 'published', 'archived'] } }
  #     }))
  #     expect(dimension.all_values).to eq described_class.
  #   end
  # end

  # describe '#filter' do
  #   it 'filters to rows matching at least one value' do
  #     p1 = create(:post, author: 'Alice')
  #     p2 = create(:post, author: 'Bob')
  #     p3 = create(:post, author: nil)

  #     def filter_by(author_values)
  #       report = OpenStruct.new(
  #         table_name: 'posts',
  #         params: { dimensions: { author: { only: author_values } } }
  #       )
  #       dimension = author_dimension(report)
  #       dimension.filter(dimension.relate(Post))
  #     end

  #     expect(filter_by(['Alice'])).to eq [p1]
  #     expect(filter_by([nil])).to eq [p3]
  #     expect(filter_by(['Alice', nil])).to eq [p1, p3]
  #     expect(filter_by(['Alice', 'Bob'])).to eq [p1, p2]
  #     expect(filter_by([])).to eq []
  #   end
  # end

  # describe '#group' do
  #   it 'groups the relation by the exact value of the SQL expression' do
  #     p1 = create(:post, author: 'Alice')
  #     p2 = create(:post, author: 'Alice')
  #     p3 = create(:post, author: nil)
  #     p4 = create(:post, author: 'Bob')
  #     p5 = create(:post, author: 'Bob')
  #     p6 = create(:post, author: 'Bob')

  #     report = OpenStruct.new(table_name: 'posts', params: {})
  #     dimension = author_dimension(report)

  #     results = dimension.group(dimension.relate(Post)).select("COUNT(*) AS count").map do |r|
  #       r.attributes.values_at(dimension.send(:sql_value_name), 'count')
  #     end

  #     expect(results).to eq [[nil, 1], ['Alice', 2], ['Bob', 3]]
  #   end
  # end

  
end
