# frozen_string_literal: true

class LandingPage < ApplicationRecord
  attr_accessor :blocks_json

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validate :hero_cta_url_safe
  validate :blocks_structure

  before_validation :normalize_slug
  before_validation :parse_blocks_json, if: -> { blocks_json.present? }

  scope :published, -> { where(published: true) }

  def blocks_json
    @blocks_json || JSON.pretty_generate(blocks || [])
  end

  def safe_url(url)
    return nil if url.blank?

    value = url.to_s.strip
    return value if value.start_with?("/")

    uri = URI.parse(value)
    return value if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    nil
  rescue URI::InvalidURIError
    nil
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize
  end

  def parse_blocks_json
    self.blocks = JSON.parse(blocks_json)
  rescue JSON::ParserError
    errors.add(:blocks, :invalid)
    errors.add(:blocks_json, :invalid)
  end

  def blocks_structure
    return if blocks.blank?
    return errors.add(:blocks, :invalid) unless blocks.is_a?(Array)

    blocks.each do |block|
      unless block.is_a?(Hash) && block["type"].present?
        errors.add(:blocks, :invalid)
        break
      end

      if block["type"] == "cta" && block["button_url"].present? && safe_url(block["button_url"]).nil?
        errors.add(:blocks_json, :invalid)
        break
      end
    end
  end

  def hero_cta_url_safe
    return if hero_cta_url.blank?
    return if safe_url(hero_cta_url).present?

    errors.add(:hero_cta_url, :invalid)
  end
end
