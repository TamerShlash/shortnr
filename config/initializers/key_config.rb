KEY_CONFIG = {
  regexp: /[\w-]{6}/,
  size: ENV.fetch('KEY_SIZE', 4).to_i,
  length: (ENV.fetch('KEY_SIZE', 4).to_i * 4 / 3.0).ceil
}.freeze
