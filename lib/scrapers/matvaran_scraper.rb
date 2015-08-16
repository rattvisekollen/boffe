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

    {}.tap do |product|
      product[:source] = :matvaran
      product[:source_url] = url

      product[:barcode] = url.split("?").last

      product[:img_url] = doc.css(".opacity.fancyBoxAuto")[0].xpath("img").first.attributes["src"].value

      product[:name_raw] = doc.css(".vara").first.text
      product[:name] = product[:name_raw]

      product[:manufacturer_raw] = anchor.xpath("div")[0].xpath("a").text
      product[:manufacturer] = product[:manufacturer_raw]

      product[:origin_raw] = anchor.text
      product[:origin_raw] = product[:origin_raw].split("Ursprung")[1] if product[:origin_raw]
      product[:origin_raw] = product[:origin_raw].strip if product[:origin_raw]
      product[:origin] = product[:origin_raw]

      product[:ingredients_raw] = anchor.text
      product[:ingredients_raw] = product[:ingredients_raw].split("Ingrediensförteckning")[1] if product[:ingredients_raw]
      product[:ingredients_raw] = product[:ingredients_raw].split("Näringsvärden")[0] if product[:ingredients_raw]
      product[:ingredients] = parse_ingredients(product[:ingredients_raw])
    end
  end

  def parse_ingredients(ingredients)
    return [] if ingredients.blank?

    filtered_words = [
      "ingredienser",
      "garnering",
      "konserveringsmedel",
      "färgämne",
      "färgämnen",
      "emulgeringsmedel",
      "stabiliseringsmedel"
    ]

    percent_pattern = /[0-9,]+\s*%/
    filtered_words_pattern = /(#{ filtered_words.join('|') })/
    illegal_chars_pattern = /[:\r\n\t\*]/
    separator_pattern = /[\(\),.]/

    ingredients = ingredients.mb_chars.downcase.to_s
    ingredients = ingredients.gsub("och", " ")
    ingredients = ingredients.gsub(/\s+/, " ")
    ingredients = ingredients.gsub(percent_pattern, "")
    ingredients = ingredients.gsub(illegal_chars_pattern, "")
    ingredients = ingredients.gsub(filtered_words_pattern, "")
    ingredients = ingredients.split(separator_pattern)
    ingredients = ingredients.reject(&:blank?)
    ingredients = ingredients.map(&:strip)
    ingredients = ingredients.reject { |s| s.start_with?("motsvarar") }
  end
end
