# frozen_string_literal: true

FactoryBot.define do
  factory :author do
    name { Faker::Name.name }
  end

  factory :comment do
    author
  end

  factory :post do
    author
    status { :published }
  end
end
