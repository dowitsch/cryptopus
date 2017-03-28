# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require_relative '../../../app/controllers/authentication/user_authenticator.rb'
require_relative '../../../app/controllers/authentication/brute_force_detector.rb'
require 'test_helper'

class UserAuthenticatorTest < ActiveSupport::TestCase

  test 'authenticates bob with API-Key' do
    @params = {api_id: users(:alice_api).id, api_key: alice_api_key}

    assert_equal true, api_key_authenticate
  end

  test 'authentication invalid with wrong API-Key' do
    @params = {api_id: users(:alice_api).id, api_key: 'wrongkey'}

    assert_equal false, api_key_authenticate
  end

  test 'authentication invalid if blank API-Key' do
    @params = {api_id: users(:alice_api).id, api_key: ''}

    assert_equal false, api_key_authenticate
  end

  test 'authenticates bob with password' do
    @params = {username: 'bob', password: 'password'}

    assert_equal true, password_authenticate
  end

  test 'authentication invalid if blank password' do
    @params = {username: 'bob', password: ''}

    assert_equal false, password_authenticate
  end

  test 'authenticates against ldap' do
    @params = {username: 'bob', password: 'ldappw'}
    bob.update_attribute(:auth, 'ldap')
    LdapTools.expects(:ldap_login).with('bob', 'ldappw').returns(true)
    assert_equal true, password_authenticate
  end

  test 'doesnt authenticate against ldap' do
    @params = {username: 'bob', password: 'wrongldappw'}
    bob.update_attribute(:auth, 'ldap')
    LdapTools.expects(:ldap_login).with('bob', 'wrongldappw').returns(false)

    assert_equal false, password_authenticate
  end

  test 'increasing of failed login attempts and it\'s defined delays with password api key auth' do
    @params = {api_id: alice_api.id, api_key: 'wrongapikey'}
    locktimes = [0, 0, 0, 3, 5, 20, 30, 60, 120, 240].freeze
    assert_equal 10, Authentication::BruteForceDetector::LOCK_TIME_FAILED_LOGIN_ATTEMPT.length

    authenticator_api = authenticator
    authenticator_api.instance_variable_set('@authenticator_class', ::ApiKey)

    locktimes.each_with_index do |timer, i|
      attempt = i + 1

      last_failed_login_time = DateTime.now.utc - locktimes[i].seconds
      alice_api.update!({last_failed_login_attempt_at: last_failed_login_time})

      assert_equal false, authenticator_api.send(:user_locked?), 'alice_api should should not be locked temporarly'

      Authentication::UserAuthenticator.new(@params).api_key_auth!

      if attempt == locktimes.count
        assert_equal true, alice_api.reload.locked?, 'alice_api should be logged after 10 failed login attempts'
        break
      end

      assert_equal attempt, alice_api.reload.failed_login_attempts
      assert last_failed_login_time.to_i <= alice_api.last_failed_login_attempt_at.to_i

    end
  end

  test 'increasing of failed login attempts and it\'s defined delays with password auth' do
    @params = {username: 'bob', password: 'wrong password'}
    locktimes = [0, 0, 0, 3, 5, 20, 30, 60, 120, 240].freeze
    assert_equal 10, Authentication::BruteForceDetector::LOCK_TIME_FAILED_LOGIN_ATTEMPT.length

    locktimes.each_with_index do |timer, i|
      attempt = i + 1

      last_failed_login_time = DateTime.now.utc - locktimes[i].seconds
      bob.update!({last_failed_login_attempt_at: last_failed_login_time})

      assert_equal false, authenticator.send(:user_locked?), 'bob should should not be locked temporarly'

      Authentication::UserAuthenticator.new(@params).password_auth!

      if attempt ==  locktimes.count
        assert_equal true, bob.reload.locked?, 'bob should be logged after 10 failed login attempts'
        break
      end

      assert_equal attempt, bob.reload.failed_login_attempts
      assert last_failed_login_time.to_i <= bob.last_failed_login_attempt_at.to_i

    end
  end


  test 'authentication fails if required params missing' do
    @params = {}

    assert_equal false, password_authenticate
    assert_match /Invalid user \/ password/, authenticator.errors.first
  end

  test 'authentication fails if invalid credentials' do
    @params = {username: 'bob', password: 'invalid'}

    assert_equal false, password_authenticate
    assert_match /Invalid user \/ password/, authenticator.errors.first
  end

  test 'authentication fails if user does not exist' do
    @params = {username: 'nobody', password: 'password'}

    assert_equal false, password_authenticate
    assert_match /Invalid user \/ password/, authenticator.errors.first
  end

  test 'authentication succeeds if user and password match' do
    @params = {username: 'bob', password: 'password'}

    assert_equal true, password_authenticate
  end

  private

  def alice_api_key
   "b5769035c051b99d1d45b0b89c746efc4e43b9f04668ea191bdde2373352baeb92427b9d354198c2"
  end

  def password_authenticate
    authenticator.password_auth!
  end

  def api_key_authenticate
    authenticator.api_key_auth!
  end

  def authenticator
    @authenticator ||= Authentication::UserAuthenticator.new(@params)
  end

  def bob
    users(:bob)
  end

  def alice_api
    users(:alice_api)
  end

end
