# coding: utf-8
class MatvaranScraper
  def parse(url)
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    anchor = doc.css(".icacontent_main").first.xpath("div")[1].xpath("div")[4]

    result = {}

    result[:barcode] = url.split("?").last
    result[:name] = doc.css(".vara").first.text
    result[:manufacturer] = anchor.xpath("div")[0].xpath("a").text

    ingredients = anchor.text.split("Ingrediensförteckning")[1].split("Näringsvärden")[0].mb_chars.downcase.to_s
    result[:ingredients] = ingredients.split(/[\(\),.]/).reject(&:blank?).map(&:strip)

    result
  end
end
