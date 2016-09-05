module ShortenedUrisHelper
  def short_uri_for(shortened_uri)
    "#{root_url}/#{shortened_uri.key}"
  end
end
