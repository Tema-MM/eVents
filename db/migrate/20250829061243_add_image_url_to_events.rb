class AddImageUrlToEvents < ActiveRecord::Migration[8.0]
  def change
    remove_column :events, :image_url, :string
  end
end
