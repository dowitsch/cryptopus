# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

module ControllerTest
  module DefaultHelper
    def login_as(username, password = 'password')
      user = User.find_by_username(username)
      request.session[:user_id] = user.id
      session[:private_key] = CryptUtils.decrypt_private_key( user.private_key, password )
    end

    def api_id(username)
    user = User.find_by_username(username)
    user.apikey.id
    end

    def api_key_alice
      "b5769035c051b99d1d45b0b89c746efc4e43b9f04668ea191bdde2373352baeb92427b9d354198c2"
    end
  end
end
