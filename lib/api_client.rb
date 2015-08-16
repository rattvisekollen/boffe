class ApiClient
  def initialize
    @base_url = "http://localhost:3000"
  end

  def update_product(product)
    HTTParty.put(
      "#{@base_url}/products/#{product[:barcode]}",
      body: {
        product: product
      }
    )
  end
end
