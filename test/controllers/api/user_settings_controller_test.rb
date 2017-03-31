# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::UserSettingsControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper

  test 'does toggle bobs api' do
    login_as('bob')

    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey

    xhr :patch, :toggle_api, user_setting_id: users(:bob).id

    assert_equal true, users(:bob).api_is_activated?

    users(:bob).toggle_api(users(:bob), session[:private_key])

    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey
  end
end
