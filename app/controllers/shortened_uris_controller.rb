class ShortenedUrisController < ApplicationController
  def show
  end

  def new
    @shortened_uri = ShortenedUri.new
  end

  def create
    @shortened_uri = ShortenedUri.new(shortened_uri_params)

    if @shortened_uri.save
      redirect_to @shortened_uri, notice: 'Shortened uri was successfully created.'
    else
      render :new
    end
  end

  private

  def shortened_uri_params
    params.require(:shortened_uri).permit(:original_uri)
  end
end
