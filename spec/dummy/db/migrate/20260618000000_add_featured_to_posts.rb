class AddFeaturedToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :featured, :boolean, null: false, default: false
  end
end
