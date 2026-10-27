class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.integer :stock
      t.string :category
      t.boolean :active

      t.timestamps
    end
  end
end
