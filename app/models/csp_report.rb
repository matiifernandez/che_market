# frozen_string_literal: true

class CspReport < ApplicationRecord
  validates :occurred_at, presence: true
end
