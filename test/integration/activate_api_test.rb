# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'
class ActivateApi < ActionDispatch::IntegrationTest
  include IntegrationTest::DefaultHelper


  test 'does not activate api for other user' do
    login_as('alice')

    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey

    assert_raise "user is not allowed to activate/deactivate api for this user" do
      users(:alice).toggle_api(users(:bob), session[:private_key])
    end
    assert_equal false, users(:bob).api_is_activated?
    assert_nil users(:bob).apikey
  end


  test 'does not deactivate api for other user' do
    login_as('bob')

    assert_equal true, users(:alice).api_is_activated?

    assert_raise "user is not allowed to activate/deactivate api for this user" do
      users(:bob).toggle_api(users(:alice), session[:private_key])
    end
    assert_equal true, users(:alice).api_is_activated?
    assert users(:alice).apikey
  end

end
