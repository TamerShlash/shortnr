require 'rails_helper'

RSpec.describe 'ShortenedUris', type: :request do
  let(:valid_uri) { 'http://user:pass@shla.sh:123/foo?bar=baz#quux' }

  describe 'POST /' do
    context 'when supplied original URL is invalid' do
      it 'does not create any records' do
        expect(REDIS).not_to receive(:multi)
        post '/', params: { shortened_uri: { original_uri: 'invalid uri' } }
      end

      it 'returns error status and message' do
        post '/', params: { shortened_uri: { original_uri: 'invalid uri' } }
        expect(response.status).to eq(400)
        expect(response.body).to include('not a valid URI')
      end
    end

    context 'when supplied original URL is valid' do
      it 'creates a shortened uri and saves it using #write method' do
        expect_any_instance_of(ShortenedUri).to receive(:write).and_call_original
        post '/', params: { shortened_uri: { original_uri: valid_uri } }
      end

      it 'returns success status and message' do
        post '/', params: { shortened_uri: { original_uri: valid_uri } }
        expect(response.status).to eq(200)
        expect(response.body).to include('created successfully')
      end
    end
  end

  describe 'GET /:key' do
    context 'when the key does not exist' do
      it 'returns 404 status and page' do
        expect { get '/abcdef' }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the key is cached' do
      it 'does not hit the database' do
        key = ShortenedUri.new(original_uri: valid_uri).write.key
        expect(ShortenedUri).not_to receive(:find_by)
        get "/#{key}"
      end

      it 'returns 302 status and redirects to the original URI' do
        key = ShortenedUri.new(original_uri: valid_uri).write.key
        get "/#{key}"
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to eq(valid_uri)
      end
    end

    context 'when the key is no cached' do
      it 'is fetched from the database' do
        key = ShortenedUri.create(original_uri: valid_uri).key
        expect(ShortenedUri).to receive(:find_by).and_call_original
        get "/#{key}"
      end

      it 'is loaded to cache' do
        key = ShortenedUri.create(original_uri: valid_uri).key
        expect(REDIS).to receive(:setex).and_call_original
        get "/#{key}"
      end

      it 'returns 302 status and redirects to the original URI' do
        key = ShortenedUri.new(original_uri: valid_uri).write.key
        get "/#{key}"
        expect(response.status).to eq(302)
        expect(response.headers['Location']).to eq(valid_uri)
      end
    end
  end
end
