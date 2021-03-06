# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'openssl'
require 'digest/sha1'

include OpenSSL

class CryptUtils
  @@magic = 'Salted__'
  @@salt_length = 8
  @@cypher = 'aes-256-cbc'

  class << self
    def one_way_crypt(plaintext_password)
      salt = SecureRandom.hex
      "sha512$#{salt}$" + Digest::SHA512.hexdigest(salt+plaintext_password)
    end

    def legacy_one_way_crypt(password)
      Digest::SHA1.hexdigest(password)
    end

    def new_keypair
      keypair = PKey::RSA.new(2048)
      keypair
    end

    def get_private_key_from_keypair(keypair)
      keypair.to_s
    end

    def get_public_key_from_keypair(keypair)
      keypair.public_key.to_s
    end

    def decrypt_team_password(team_password, private_key)
      keypair = PKey::RSA.new(private_key)
      decrypted_team_password = keypair.private_decrypt(team_password)
      return decrypted_team_password
    rescue
      return nil
    end

    def encrypt_team_password(team_password, public_key)
      keypair = PKey::RSA.new(public_key)
      encrypted_team_password = keypair.public_encrypt(team_password)
      return encrypted_team_password

    rescue
      return nil
    end

    def new_team_password
      cipher = OpenSSL::Cipher::Cipher.new(@@cypher)
      team_password = cipher.random_key
      team_password
    end

    def encrypt_api_key(public_key, plain_api_key)
      keypair = PKey::RSA.new(public_key)
      encrypted_api_key = keypair.public_encrypt(plain_api_key)
      return encrypted_api_key

    rescue
      return nil
    end

    def decrypt_api_key(private_key, api_key)
      keypair = PKey::RSA.new(private_key)
      decrypted_api_key = keypair.private_decrypt(api_key)
      return decrypted_api_key
    rescue
      return nil
    end

    def encrypt_private_key(private_key, password)
      cipher = OpenSSL::Cipher::Cipher.new(@@cypher)
      cipher.encrypt
      salt = OpenSSL::Random.pseudo_bytes @@salt_length
      cipher.pkcs5_keyivgen password, salt, 1000
      private_key_part = cipher.update(private_key) + cipher.final

      @@magic + salt + private_key_part
    end

    def decrypt_private_key(private_key, password)
      begin
        cipher = OpenSSL::Cipher::Cipher.new(@@cypher)
        cipher.decrypt
        unless private_key.slice(0, @@magic.size) == @@magic
          raise 'magic does not match'
        end
        salt = private_key.slice(@@magic.size, @@salt_length)
        private_key_part = private_key.slice((@@magic.size + @@salt_length)..-1)
        cipher.pkcs5_keyivgen password, salt, 1000
        return cipher.update(private_key_part) + cipher.final
      rescue
        raise Exceptions::DecryptFailed
      end
      nil
    end

    def validate_keypair(private_key, public_key)
      test_data = 'Test Data'
      encrypted_test_data = CryptUtils.encrypt_team_password(test_data, public_key)
      unless test_data == CryptUtils.decrypt_team_password(encrypted_test_data, private_key)
        raise Exceptions::DecryptFailed
      end
    end

    def encrypt_blob(blob, team_password)
      cipher = OpenSSL::Cipher::Cipher.new(@@cypher)
      cipher.encrypt
      cipher.key = team_password
      crypted_blob = cipher.update(blob)
      crypted_blob << cipher.final
      crypted_blob
    end

    def decrypt_blob(blob, team_password)
      cipher = OpenSSL::Cipher::Cipher.new(@@cypher)
      cipher.decrypt
      cipher.key = team_password
      decrypted_blob = cipher.update(blob)
      decrypted_blob << cipher.final
      decrypted_blob.force_encoding('UTF-8')
    end
  end

end
