# coding: utf-8
class MatvaranScraper < BaseScraper
  def scrape(url)
    product = parse(url)

    api_client.update_product(product)
  end

  def parse(url)
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    anchor = doc.css(".icacontent_main").first.xpath("div")[1].xpath("div")[4]

    result = {}

    result[:source] = :matvaran
    result[:source_url] = url
    result[:barcode] = url.split("?").last
    result[:name_raw] = doc.css(".vara").first.text
    result[:name] = result[:name_raw]
    result[:manufacturer_raw] = anchor.xpath("div")[0].xpath("a").text
    result[:manufacturer] = result[:manufacturer_raw]

    result[:origin_raw] = anchor.text
    result[:origin_raw] = result[:origin_raw].split("Ursprung")[1] if result[:origin_raw]
    result[:origin_raw] = result[:origin_raw].strip if result[:origin_raw]
    result[:origin] = result[:origin_raw]

    result[:ingredients_raw] = anchor.text
    result[:ingredients_raw] = result[:ingredients_raw].split("Ingrediensförteckning")[1] if result[:ingredients_raw]
    result[:ingredients_raw] = result[:ingredients_raw].split("Näringsvärden")[0] if result[:ingredients_raw]
    result[:ingredients] = parse_ingredients(result[:ingredients_raw])

    result
  end

  def parse_ingredients(ingredients)
    return [] if ingredients.blank?

    filtered_words = ["ingredienser", "garnering", "konserveringsmedel", "färgämne", "färgämnen"]

    percent_pattern = /[0-9,]+\s*%/
    filtered_words_pattern = /(#{ filtered_words.join('|') })/
    illegal_chars_pattern = /[:\r\n\t]/
    separator_pattern = /[\(\),.]|och/

    ingredients = ingredients.mb_chars.downcase.to_s
    ingredients = ingredients.gsub(percent_pattern, "")
    ingredients = ingredients.gsub(illegal_chars_pattern, "")
    ingredients = ingredients.gsub(filtered_words_pattern, "")
    ingredients = ingredients.split(separator_pattern)
    ingredients = ingredients.reject(&:blank?)
    ingredients = ingredients.map(&:strip)
  end
end
