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
    anchor_text = anchor.text.mb_chars.downcase.to_s

    {}.tap do |product|
      product[:source] = :matvaran
      product[:source_url] = url

      product[:barcode] = url.split("?").last

      product[:img_url] = doc.css(".opacity.fancyBoxAuto")[0].xpath("img").first.attributes["src"].value

      product[:name_raw] = doc.css(".vara").first.text
      product[:name] = product[:name_raw].mb_chars.downcase.to_s if product[:name_raw]

      product[:brand_raw] = anchor.xpath("div")[0].xpath("a").text
      product[:brand] = product[:brand_raw].mb_chars.downcase.to_s if product[:brand_raw]

      product[:origin_raw] = anchor_text
      product[:origin_raw] = product[:origin_raw].split("ursprung")[-2] if product[:origin_raw]
      product[:origin_raw] = product[:origin_raw].split("\.")[0] if product[:origin_raw]
      product[:origin_raw] = product[:origin_raw].strip if product[:origin_raw]
      product[:origin] = product[:origin_raw].mb_chars.downcase.to_s if product[:origin_raw]

      product[:ingredients_raw] = anchor_text
      product[:ingredients_raw] = product[:ingredients_raw] if product[:ingredients_raw]
      product[:ingredients_raw] = product[:ingredients_raw].split("ingrediensförteckning")[1] if product[:ingredients_raw]
      product[:ingredients_raw] = product[:ingredients_raw].split(/näringsinnehåll|näringsvärden/)[0] if product[:ingredients_raw]
      product[:ingredients] = parse_ingredients(product[:ingredients_raw])

      product[:eu_organic] = true if doc.css("img[src*='http://static.matvaran.se/ica_produkt/eulovet.png']").any?
    end
  end

  def parse_ingredients(ingredients)
    return [] if ingredients.blank?

    filtered_words_pattern = /(#{ word_filter_before.join('|') })/
    percent_pattern = /[0-9,\.]+\s*%/
    illegal_chars_pattern = /[:\r\n\t]/
    separator_pattern = /[\(\),.\*®\|]/

    ingredients = ingredients.mb_chars.downcase.to_s
    ingredients = ingredients.gsub(filtered_words_pattern, "")
    word_replacements.each { |a, b| ingredients = ingredients.gsub(a, b) }
    ingredients = ingredients.gsub("och ", ",")
    ingredients = ingredients.gsub(/\s+/, " ")
    ingredients = ingredients.gsub(percent_pattern, "")
    ingredients = ingredients.gsub(illegal_chars_pattern, "")
    ingredients = ingredients.split(separator_pattern)
    ingredients = ingredients.reject(&:blank?)
    ingredients = ingredients.map(&:strip)
    ingredients = ingredients.reject { |s| s.start_with?("motsvarar") }
    ingredients = ingredients - word_filter_after
  end

  def word_filter_before
    [
      "ingredienser",
      "lågpastöriserad",
      "högpastöriserad",
      "berikad med",
      "bl.a.",
      "bl a",
      "innehåller också",
      "1l",
      "1 l",
      "/mælkeprotein",
      "/mælk",
      "/højpasteuriseret",
      "/jordbær",
      "/hyldebær-",
      "/piskefløde",
    ]
  end

  def word_filter_after
    [
      "uht-behandlad",
      "eu-jordbruk",
      "fetthalt",
      "ej homogeniserad",
      "garnering",
      "konserveringsmedel",
      "färgämne",
      "färgämnen",
      "emulgeringsmedel",
      "förtjockningsmedel",
      "stabiliseringsmedel",
      "surhetsreglerande medel",
      "surhetsreglerandemedel",
      "krav- ekologisk ingrediens ej standardiserad",
      "krav-ekologisk ingrediens",
      "se",
      "dk",
      "kryddextrakter",
      "kryddextrakt",
      "antioxidationsmedel",
      "kryddor",
      "bärberedning",
      "färg",
      "aromer",
      "kalcium bidrar till att matsmältningsenzymerna fungerar normalt",
      "naturlig arom",
      "naturliga aromer",
      "inkl",
      "sötningsmedel",
      "tillsatt",
      "smakberedning",
      "svensk mjölkråvara",
      "produkten innehåller",
      "andra",
      "ursprung sverige",
      "svenskt",
      "mjölken är",
      "krav-",
      "vitaminer",
      "lämplig för veganer",
      "ekologisk ingrediens",
      "syra",
      "vatten",
    ]
  end

  def word_replacements
    {
      "gris- och nötkött" => "griskött, nötkött"
    }
  end
end
