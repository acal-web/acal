class Session < ApplicationRecord
  belongs_to :user

  before_create :set_expiry

  TTL = 30.days

  def self.start_for!(user, user_agent: nil, ip_address: nil)
    raw_token = SecureRandom.hex(32)
    session = create!(
      user: user,
      token_digest: digest(raw_token),
      user_agent: user_agent,
      ip_address: ip_address
    )
    [ session, raw_token ]
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.find_active_by_token(raw_token)
    return nil if raw_token.blank?

    session = find_by(token_digest: digest(raw_token))
    return nil unless session && session.expires_at.future?

    session
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  private

  def set_expiry
    self.expires_at ||= TTL.from_now
  end
end
