# frozen_string_literal: true

class LandingPage < ApplicationRecord
  attr_accessor :blocks_json

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validate :blocks_structure

  before_validation :normalize_slug
  before_validation :parse_blocks_json, if: -> { blocks_json.present? }

  scope :published, -> { where(published: true) }

  def blocks_json
    @blocks_json || JSON.pretty_generate(blocks || [])
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize
  end

  def parse_blocks_json
    self.blocks = JSON.parse(blocks_json)
  rescue JSON::ParserError
    errors.add(:blocks, :invalid)
  end

  def blocks_structure
    return if blocks.blank?
    return errors.add(:blocks, :invalid) unless blocks.is_a?(Array)

    blocks.each do |block|
      unless block.is_a?(Hash) && block["type"].present?
        errors.add(:blocks, :invalid)
        break
      end
    end
  end
end
