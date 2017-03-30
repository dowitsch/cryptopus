# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.
class User::ApiKey < User
  belongs_to :origin_user, class_name: 'User', foreign_key: :origin_user_id

  def create(origin_user, private_key)
    self.origin_user_id = origin_user.id
    plain_api_key = CryptUtils.new_api_key
    self.api_key = CryptUtils.encrypt_api_key(origin_user.public_key, plain_api_key)
    self.private_key = CryptUtils.encrypt_private_key(private_key, plain_api_key)
    self.public_key = origin_user.public_key
    self.username = origin_user.username + '_api'
    self.save!
  end

  def decrypted_api_key(private_key)
    CryptUtils.decrypt_api_key(private_key, self.api_key)
  end

end
