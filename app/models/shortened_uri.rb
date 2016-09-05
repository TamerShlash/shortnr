class ShortenedUri < ApplicationRecord
  validates :key, presence: true
  validates :key, format: { with: KEY_CONFIG[:regexp] }
  validates :key, length: { is: KEY_CONFIG[:length] }
  validates :original_uri, presence: true
  validates :original_uri, format: {
    with: URI.regexp,
    message: 'is not a valid URI'
  }, allow_blank: true

  after_initialize :generate_key

  private

  def generate_key
    self.key ||= SecureRandom.urlsafe_base64(KEY_CONFIG[:size])
  end
end
