class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is invalid" }
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  before_save :downcase_email

  def full_name
    name
  end

  def active_session
    sessions.where("expires_at > ?", Time.current).first
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
