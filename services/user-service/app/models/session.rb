class Session < ApplicationRecord
  belongs_to :user

  validates :expires_at, presence: true
  validates :token, presence: true, uniqueness: true, allow_blank: false

  before_validation :generate_token, if: -> { token.blank? }, on: :create
  before_validation :set_expiry, if: -> { expires_at.blank? }, on: :create

  scope :valid, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def valid_session?
    expires_at > Time.current
  end

  def extend_expiry!
    update!(expires_at: 24.hours.from_now)
  end

  def self.cleanup_expired
    expired.destroy_all
  end

  private

  def generate_token
    self.token = SecureRandom.uuid
  end

  def set_expiry
    self.expires_at = 24.hours.from_now
  end
end
