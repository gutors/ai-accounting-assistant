module WrapKey
  NAME = "SEFAZ_WRAP_KEY"
  SALT = "sefaz-certificate"

  class Missing < StandardError; end

  module_function

  def present?
    ENV[NAME].present?
  end

  def encrypt(plaintext)
    encryptor.encrypt_and_sign(plaintext)
  end

  def decrypt(ciphertext)
    encryptor.decrypt_and_verify(ciphertext)
  end

  def encryptor
    raise Missing unless present?

    key = ActiveSupport::KeyGenerator.new(ENV.fetch(NAME)).generate_key(SALT, 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
