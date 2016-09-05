require 'rails_helper'

RSpec.describe 'ShortenedUris', type: :request do
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
      let(:valid_uri) { 'http://user:pass@shla.sh:123/foo?bar=baz#quux' }

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
end
