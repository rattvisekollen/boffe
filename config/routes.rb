Rails.application.routes.draw do
  post "/scrape" => "scrape#scrape"
end
