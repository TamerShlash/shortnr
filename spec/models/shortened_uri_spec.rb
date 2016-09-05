require 'rails_helper'

RSpec.describe ShortenedUri, type: :model do
  # TODO: use FactoryGirl instead
  let(:valid_uri) { 'http://user:pass@shla.sh:123/foo?bar=baz#quux' }
  let(:random_key) { SecureRandom.urlsafe_base64(KEY_CONFIG[:size]) }

  describe '#key' do
    context 'when not supplied' do
      it 'is auto-generated' do
        expect(ShortenedUri.new.key).to be_present
      end

      it 'is random' do
        keys = Array.new(100) { ShortenedUri.new.key }
        expect(keys.uniq.length).to eq(100)
      end

      it 'has specific number of characters' do
        shortened_uris = Array.new(100) { ShortenedUri.new }

        shortened_uris.each do |shortened_uri|
          expect(shortened_uri.key.length).to eq(KEY_CONFIG[:length])
        end
      end

      it 'is URL safe' do
        shortened_uris = Array.new(100) { ShortenedUri.new }

        shortened_uris.each do |shortened_uri|
          expect(shortened_uri.key).to match(KEY_CONFIG[:regexp])
        end
      end
    end

    context 'when supplied' do
      it 'is not auto-generated if supplied' do
        key = random_key
        shortened_uri = ShortenedUri.new(key: key)
        expect(shortened_uri.key).to eq(key)
      end

      it 'cannot be blank' do
        shortened_uri = ShortenedUri.new(key: '', original_uri: valid_uri)
        expect(shortened_uri).not_to be_valid
        expect(shortened_uri.errors).to have_key(:key)
      end

      it 'is not valid if not URL-safe' do
        shortened_uri = ShortenedUri.new(key: '@bcdef', original_uri: valid_uri)
        expect(shortened_uri).not_to be_valid
        expect(shortened_uri.errors).to have_key(:key)
        shortened_uri.key = random_key
        expect(shortened_uri).to be_valid
      end

      it 'has to have specific length' do
        shortened_uri = ShortenedUri.new(key: 'a', original_uri: valid_uri)
        expect(shortened_uri).not_to be_valid
        expect(shortened_uri.errors).to have_key(:key)
        shortened_uri.key = random_key
        expect(shortened_uri).to be_valid
      end
    end

    it 'is not auto-generated for persisted records' do
      key = ShortenedUri.create(original_uri: 'http://shla.sh').key
      expect(key).to be_present
      shortened_uri = ShortenedUri.find_by(key: key)
      expect(shortened_uri.key).to eq(key)
    end
  end

  describe '#original_uri' do
    it 'cannot be blank' do
      shortened_uri = ShortenedUri.new
      expect(shortened_uri).not_to be_valid
      expect(shortened_uri.errors).to have_key(:original_uri)
    end

    it 'is invalid if the value is not a valid URI' do
      shortened_uri = ShortenedUri.new(original_uri: 'foo')
      expect(shortened_uri).not_to be_valid
      expect(shortened_uri.errors[:original_uri]).to include('is not a valid URI')
    end

    it 'is valid if the value is a valid URI' do
      shortened_uri = ShortenedUri.new(original_uri: valid_uri)
      expect(shortened_uri).to be_valid
    end
  end

  describe '#write' do
    context 'when record is invalid' do
      let(:invalid_record) { ShortenedUri.new(original_uri: 'invalid') }
      it 'returns false' do
        expect(invalid_record.write).to be(false)
      end

      it 'does not save the record in cache' do
        invalid_record.write
        expect(REDIS.get(ShortenedUri.cache_key(invalid_record.key))).to be_blank
      end

      it 'does not save the record to db' do
        invalid_record.write
        expect(ShortenedUri.find_by(key: invalid_record.key)).to be_blank
      end

      it 'does not add the record to queue to be persisted' do
        invalid_record.write
        expect(REDIS.hget(ShortenedUri::QUEUE_REDIS_KEY, invalid_record.key)).to be_blank
      end
    end

    context 'when record is valid' do
      let(:shortened_uri) { ShortenedUri.new(original_uri: valid_uri) }

      it 'returns self (chainable)' do
        expect(shortened_uri.write).to be(shortened_uri)
      end

      it 'saves the record in cache' do
        expect(REDIS.get(ShortenedUri.cache_key(shortened_uri.key))).to be_blank
        shortened_uri.write
        expect(REDIS.get(ShortenedUri.cache_key(shortened_uri.key))).to eq(valid_uri)
      end

      it 'does not save the record to db' do
        shortened_uri.write
        expect(ShortenedUri.find_by(key: shortened_uri.key)).to be_blank
      end

      it 'adds the record to queue to be persisted' do
        expect(REDIS.hget(ShortenedUri::QUEUE_REDIS_KEY, shortened_uri.key)).to be_blank
        shortened_uri.write
        expect(REDIS.hget(ShortenedUri::QUEUE_REDIS_KEY, shortened_uri.key)).to eq(valid_uri)
      end
    end
  end

  describe '.fetch' do
    context 'when the record is cached' do
      it 'does not hit the database' do
        key = ShortenedUri.new(original_uri: valid_uri).key
        REDIS.set(ShortenedUri.cache_key(key), valid_uri)
        expect(ShortenedUri).not_to receive(:find_by)
        shortened_uri = ShortenedUri.fetch(key)
        expect(shortened_uri.key).to eq(key)
        expect(shortened_uri.original_uri).to eq(valid_uri)
      end
    end

    context 'when the record is not cached' do
      it 'hits the database' do
        key = ShortenedUri.create(original_uri: valid_uri).key
        expect(ShortenedUri).to receive(:find_by!).and_call_original
        shortened_uri = ShortenedUri.fetch(key)
        expect(shortened_uri.key).to eq(key)
        expect(shortened_uri.original_uri).to eq(valid_uri)
      end

      it 'loads it to cache' do
        key = ShortenedUri.create(original_uri: valid_uri).key
        expect(REDIS.get(ShortenedUri.cache_key(key))).to be_blank
        ShortenedUri.fetch(key)
        expect(REDIS.get(ShortenedUri.cache_key(key))).to eq(valid_uri)
      end
    end
  end

  describe '.persist_new_records' do
    let(:sample_keys) do
      Array.new(10) { |i| ShortenedUri.new(original_uri: "#{valid_uri}#{i}").write.key }
    end

    it 'saves new records to database' do
      expect(ShortenedUri.where(key: sample_keys)).to be_blank
      ShortenedUri.persist_new_records
      expect(ShortenedUri.where(key: sample_keys).length).to eq(10)
    end

    it 'removes saved records from queue' do
      sample_keys
      expect(REDIS.hgetall(ShortenedUri::QUEUE_REDIS_KEY).keys).to eq(sample_keys)
      ShortenedUri.persist_new_records
      expect(REDIS.hgetall(ShortenedUri::QUEUE_REDIS_KEY).keys).to be_blank
    end
  end
end
