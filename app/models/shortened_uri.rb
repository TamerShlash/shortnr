class ShortenedUri < ApplicationRecord
  CACHE_TTL = 10.days.to_i
  QUEUE_REDIS_KEY = 'queued_shortened_uris'.freeze
  REDIS_KEY_PREFIX = 'shortened:'.freeze

  validates :key, presence: true
  validates :key, format: { with: KEY_CONFIG[:regexp] }
  validates :key, length: { is: KEY_CONFIG[:length] }
  validates :original_uri, presence: true
  validates :original_uri, format: {
    with: URI.regexp,
    message: 'is not a valid URI'
  }, allow_blank: true

  after_initialize :generate_key
  after_find :save_to_cache

  class << self
    def fetch(key)
      find_from_cache(key) || find_and_cache(key)
    end

    # TODO: consider moving this job to its own service class
    def persist_new_records
      columns = [:key, :original_uri]
      new_records = REDIS.hgetall(QUEUE_REDIS_KEY)
      return if new_records.blank?
      ShortenedUri.import(columns, new_records.to_a, validate: false)
      REDIS.hdel(QUEUE_REDIS_KEY, new_records.keys)
    end

    def cache_key(key)
      "#{REDIS_KEY_PREFIX}#{key}"
    end

    private

    def find_from_cache(key)
      original_uri = REDIS.get(cache_key(key))
      original_uri.present? ? new(key: key, original_uri: original_uri) : nil
    end

    def find_and_cache(key)
      find_by!(key: key)
    end
  end

  def write
    return false unless valid?
    REDIS.multi do
      save_to_cache
      queue_to_persist
    end
    self
  end

  private

  def cache_key
    ShortenedUri.cache_key(key)
  end

  def generate_key
    self.key ||= SecureRandom.urlsafe_base64(KEY_CONFIG[:size])
  end

  def save_to_cache
    REDIS.setex(cache_key, CACHE_TTL, original_uri)
  end

  def queue_to_persist
    REDIS.hset(QUEUE_REDIS_KEY, key, original_uri)
  end
end
