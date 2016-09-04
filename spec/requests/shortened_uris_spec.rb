require 'rails_helper'

RSpec.describe "ShortenedUris", type: :request do
  describe "GET /shortened_uris" do
    it "works! (now write some real specs)" do
      get shortened_uris_path
      expect(response).to have_http_status(200)
    end
  end
end
