# frozen_string_literal: true

class CreateReviewHelpfulVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :review_helpful_votes do |t|
      t.references :review, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :review_helpful_votes, [:review_id, :user_id], unique: true
  end
end
