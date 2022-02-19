# Funny wrapper that tries to call Google's
# gif-for-cli and if that fails, falls back to
# putting the gif URL in the terminal
class GifPrinter
  # URL => TIMES
  SUCCESS_URLS = [
    { "https://tenor.com/view/bird-dance-party-jam-parrot-gif-16443709": 3 },
    { "https://tenor.com/view/celebration-confetti-happy-success-cat-gif-14711354": 1 },
    { "https://tenor.com/view/happy-dancing-celebrate-excited-gif-13870839": 1 },
    { "https://tenor.com/view/pichu-anime-pokemon-cute-hello-gif-16560156": 3 },
    { "https://tenor.com/view/letter-w-gif-9063767": 1 }
  ]
  FAILURE_URLS = [
    { "https://tenor.com/view/homer-homer-simpson-bush-disappear-goodbye-gif-15315194": 1 },
    { "https://tenor.com/view/bye-bye-pokemon-pikachu-wave-cute-gif-17180896": 3 },
    { "https://tenor.com/view/dip-cya-im-gone-see-yah-later-gif-14648038": 1 },
    { "https://tenor.com/view/michael-scott-crying-sad-ok-sentimental-gif-20646789": 1 },
    { "https://tenor.com/view/red-alphabet-letter-dancing-letter-l-cartoons-gif-12084376": 1 }
  ]

  URL_MAP = {
    success: SUCCESS_URLS,
    failure: FAILURE_URLS
  }

  def has_executable?
    system("which gif-for-cli > /dev/null")
  end

  def print(type : Symbol)
    if has_executable?
      hash = URL_MAP[type].shuffle.first
      url = hash.keys.first
      count = hash.values.first
      system "gif-for-cli #{url} --cols 50 -c \u2588 --display-mode=truecolor -l #{count}"
    else
      puts URL_MAP[type]
    end
  end
end
