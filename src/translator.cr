# Only thing supported right now is Google Transalte

class Translator
  TRANSLATE_API_URL = "https://translation.googleapis.com/language/translate/v2"

  # TODO: Add support for fibers and pooling to make this faster
  # right now its really slow
  def translate(array : Array(String), from : String, to : String) : Array(String)
    full_translations = [] of String

    array.each_slice(128) do |slice|
      params = URI::Params.encode({
        q: slice,
        target: to,
        source: from,
        key: ENV["GOOGLE_TRANSLATE_API_KEY"]
      })

      response = HTTP::Client.get("#{TRANSLATE_API_URL}?#{params}")
      full_translations.concat(JSON.parse(response.body)["data"]["translations"].as_a
                                   .map { |translation| translation["translatedText"].as_s })
    end

    full_translations
  end
end
