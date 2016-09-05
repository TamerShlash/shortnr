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
end
