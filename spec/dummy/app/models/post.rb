# frozen_string_literal: true

class Post < ActiveRecord::Base
  enum :status, { draft: 0, unpublished: 1, published: 2, archived: 3 }
  enum :category, [:art, :literature, :travel]
  belongs_to :author, optional: true
  has_many :comments
end
