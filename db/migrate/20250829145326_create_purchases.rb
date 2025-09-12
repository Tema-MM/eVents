class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :total_price
      t.datetime :purchased_at

      t.timestamps
    end
  end
end
