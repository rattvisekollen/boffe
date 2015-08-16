class ScrapeController < ApplicationController
  def scrape
    if params[:source] == "matvaran"
      MatvaranScraper.new.scrape(params[:url])
    end

    render json: { success: true }
  end
end
