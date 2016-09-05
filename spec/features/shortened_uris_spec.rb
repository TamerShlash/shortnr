require 'rails_helper'

RSpec.feature 'ShortenedUris', type: :feature do
  scenario 'User cannot create shortened URIs for an invalid URI' do
    visit '/'

    fill_in 'original_uri', with: 'invalid url'
    click_button 'submit'

    expect(page).to have_text('not a valid URI')
  end

  scenario 'User can create shortened URIs when entering a valid URI' do
    visit '/'

    fill_in 'original_uri', with: 'http://user:pass@shla.sh:123/foo?bar=baz#quux'
    click_button 'submit'

    expect(page).to have_text('successfully')
  end
end
