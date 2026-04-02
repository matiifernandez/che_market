# frozen_string_literal: true

class CheckoutRiskEvaluator
  Result = Struct.new(:flags, :score, :level, :blocked?, keyword_init: true)

  def initialize(user:, email:, ip:, window_minutes: nil)
    @user = user
    @email = email
    @ip = ip
    @window_minutes = window_minutes || Rails.application.config.x.fraud.window_minutes
  end

  def evaluate
    flags = []

    flags << "velocity_ip" if @ip.present? && exceeded?(Order.where(checkout_ip: @ip), limit_for(:ip))
    flags << "velocity_user" if @user && exceeded?(Order.where(user_id: @user.id), limit_for(:user))
    flags << "velocity_email" if @email.present? && exceeded?(Order.where(email: @email), limit_for(:email))

    score = flags.size * 50
    level = if flags.empty?
      "low"
    elsif flags.size >= 2
      "high"
    else
      "medium"
    end

    Result.new(flags: flags, score: score, level: level, blocked?: flags.any?)
  end

  private

  def exceeded?(relation, limit)
    relation.where("created_at >= ?", Time.current - @window_minutes.minutes).count >= limit
  end

  def limit_for(key)
    limits = Rails.application.config.x.fraud
    case key
    when :ip then limits.max_per_ip
    when :user then limits.max_per_user
    when :email then limits.max_per_email
    else
      limits.max_per_ip
    end
  end
end
