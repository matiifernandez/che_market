# frozen_string_literal: true

class AddTrigramIndexToProductsName < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_products_on_name_trigram"
  end
end
