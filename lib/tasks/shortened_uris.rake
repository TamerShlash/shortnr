namespace :shortened_uris do
  desc 'Fetches new shortened URIs from REDIS and bulk-saves them to DB'
  task persist_new_records: :environment do
    ShortenedUri.persist_new_records
  end
end
