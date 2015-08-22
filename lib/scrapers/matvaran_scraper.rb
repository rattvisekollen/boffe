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

    filtered_words_pattern = /(#{ (word_filter_before + word_filter_nordic).join('|') })/
    percent_pattern = /[0-9,\.]+\s*%/
    illegal_chars_pattern = /[:\r\n\t]/
    separator_pattern = /[\(\);,.\*®\|]/

    ingredients = ingredients.mb_chars.downcase.to_s
    ingredients = ingredients.gsub(filtered_words_pattern, "")
    word_replacements.each do |a, b|
      ingredients = ingredients.gsub(a, b)
    end
    ingredients = ingredients.gsub("och ", ",")
    ingredients = ingredients.gsub(/\s+/, " ")
    ingredients = ingredients.gsub(percent_pattern, ",")
    ingredients = ingredients.gsub(illegal_chars_pattern, "")
    ingredients = ingredients.split(separator_pattern)
    ingredients = ingredients.reject(&:blank?)
    ingredients = ingredients.map(&:strip)
    word_filter_prefixes.each do |pre|
      ingredients = ingredients.map { |s| s.start_with?(pre) ? s.gsub(pre, "") : s }
    end
    word_filter_suffixes.each do |suf|
      ingredients = ingredients.map { |s| s.end_with?(suf) ? s.gsub(suf, "") : s }
    end
    ingredients = ingredients.map(&:strip)
    ingredients = ingredients - word_filter_after
    ingredients = ingredients.uniq
    ingredients = ingredients.reject(&:blank?)
  end

  def word_filter_before
    [
      "ingredienser",
      "lågpastöriserad",
      "högpastöriserad",
      "stabiliseringsmedel",
      "berikad med",
      "tag ur pizzan ur förpackningen och värm i ugn på 225°c i ca 9-10 min eller tills osten smält",
      "bl.a.",
      "bl a",
      "innehåller också",
      "1l",
      "1 l",
    ]
  end

  def word_filter_nordic
    [
      "/mælkeprotein",
      "/mælk",
      "/højpasteuriseret",
      "/jordbær",
      "/hyldebær-",
      "/piskefløde",
      "/sukker",
      "/mysepulver",
      "/rosin",
      "/sødestoffer",
      "/søtningsstoffer",
      "/hærdet",
      "/herdet",
      "/voks",
      "/emulgator",
      "/farvestof",
      "/sojabønnelecitin",
      "/fortykningsmiddel",
      "/overfadebehandlingmiddel",
      "/hvetemel",
      "/hvedemel",
      "/vegetabilske",
      "/oljer",
      "/olier",
      "/palme",
      "/kokos",
      "/sirup",
      "/bakepulver",
      "/bagepulver",
      "/ingefær",
      "/kryddernelliker",
      "/kan inneholde spor av mandler",
      "/kan indeholde spor af mandler",
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
      "arom",
      "från mjölk",
      "av mjölk",
      "tre ankare",
      "smakförstärkare",
      "förtjocknings-/fortykningsmiddel",
      "ytbehandlings-/overfladebehandlingsmidler",
      "fuktighetsbevarande medel",
      "delvis härdade vegetabiliska fetter",
      "vegetabiliska oljor",
      "30 gram",
      "ätfärdig",
      "salt av arspartam - acesulfam",
      "gummibas",
      "sv/no/dk",
      "fiskad i nordostatlanten fångstzon 27",
    ]
  end

  def word_filter_prefixes
    [
      "motsvarar",
      "minst",
      "hackade",
      "hackad",
      "naturlig",
      "naturliga",
      "sötningsmedel",
      "förtjockningsmedel",
      "fuktighetsbevarande medel",
      "fyllnadsmedel",
      "färgämne",
      "surhetsreglerande medel",
      "ytbehandlingsmedel",
      "antioxidationsmedel",
      "antioxidantmedel",
      "innehåller",
      "kokt",
      "rökt",
    ]
  end

  def word_filter_suffixes
    [
      "med",
    ]
  end

  def word_replacements
    {
      "gris- och nötkött" => "griskött, nötkött",
      "portionssnus dosa" => "portionssnus",
      "shea" => "sheaolja",
      "palm" => "palmolja",
      "raps" => "rapsolja",
      "kokosnöt" => "kokosnötsolja",
    }
  end
end
