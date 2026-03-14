# frozen_string_literal: true

class ReviewHelpfulVote < ApplicationRecord
  belongs_to :review, counter_cache: :helpful_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :review_id }
end
