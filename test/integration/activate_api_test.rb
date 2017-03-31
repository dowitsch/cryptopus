# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'
class ActivateApi < ActionDispatch::IntegrationTest
  include IntegrationTest::DefaultHelper

  test 'bob toggles api' do
    login_as('bob')

    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey

    users(:bob).toggle_api(users(:bob), session[:private_key])

    assert_equal true, users(:bob).api_is_activated?

    users(:bob).toggle_api(users(:bob), session[:private_key])

    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey
  end

end
