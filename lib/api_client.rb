class ApiClient
  def initialize
    @base_url = "http://localhost:3000"
  end

  def add_product(product)
    HTTParty.post(
      "#{@base_url}/products",
      body: {
        product: product
      }
    )
  end
end
