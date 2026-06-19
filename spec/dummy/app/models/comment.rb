class Comment < ActiveRecord::Base
  belongs_to :author, optional: true
  belongs_to :post, optional: true
end
