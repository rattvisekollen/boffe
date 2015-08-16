class BaseScraper
  def api_client
    @api_client ||= ApiClient.new
  end
end
