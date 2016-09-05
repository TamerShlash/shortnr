# Shortnr

This is a very simple URL shortening service.

## Requirements

- Ruby 2.3.1
- Postgresql database
- REDIS

## Environment Variables

- `REDIS_URL` (required): URL of the REDIS database.
- `KEY_SIZE` (optional - defaults to 4): size, in bytes, of the short URL key.

## Services

You must schedule a servie to run the following rake tasks in a frequent manner (every 1-10 minutes).

    rake shortened_uris:persist_new_records

If you are on Herkou, you can use the [https://devcenter.heroku.com/articles/scheduler](Scheduler addon)

## Testing

Running the tests is pretty straightforward using RSpec, just `cd` to the project directory and run:

    rspec
