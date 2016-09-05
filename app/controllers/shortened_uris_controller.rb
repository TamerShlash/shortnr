class ShortenedUrisController < ApplicationController
  def show
    shortened_uri = ShortenedUri.fetch(params[:key])
    redirect_to shortened_uri.original_uri, status: 302
  end

  def new
    @shortened_uri = ShortenedUri.new
  end

  def create
    @shortened_uri = ShortenedUri.new(shortened_uri_params)

    if @shortened_uri.write
      render :created, status: 200
    else
      render :new, status: 400
    end
  end

  private

  def shortened_uri_params
    params.require(:shortened_uri).permit(:original_uri)
  end
end
