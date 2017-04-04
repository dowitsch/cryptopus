# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::Team::Group::AccountsControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper

  test 'Error message if you attempt to look into a team youre not member of' do
    team = teams(:team2)
    group = groups(:group2)

    xhr :get, :index, team_id: team, group_id: group, api_key: api_key_alice, api_id: api_id('alice')

    error = JSON.parse(response.body)['messages']['errors'][0]

    assert_equal 'No Access to Team', error

  end

  test 'update account with api authentication' do
    team = teams(:team1)
    group = groups(:group1)
    account = accounts(:account1)

    xhr :put, :update, team_id: team, group_id: group, id: account,
        api_key: api_key_alice, api_id: api_id('alice'), account: {description: 'new description'}

    account_id = JSON.parse(response.body)['data']['account']['id']
    account = Account.find(account_id)

    assert_equal 'new description', account.description
  end
  test 'shows accounts from a team' do
    team = teams(:team1)
    group = groups(:group1)

    xhr :get, :index, team_id: team, group_id: group, api_key: api_key_alice, api_id: api_id('alice')

    accounts = JSON.parse(response.body)['data']['accounts']

    assert_equal 1, accounts.count
  end

  test 'return decrypted account with api authentication' do
    team = teams(:team1)
    group = groups(:group1)
    account = accounts(:account1)

    xhr :get, :show, team_id: team, group_id: group, id: account, api_key: api_key_alice, api_id: api_id('alice')
    account = JSON.parse(response.body)['data']['account']

    assert_equal 'account1', account['accountname']
    assert_equal 'test', account['cleartext_username']
    assert_equal 'password', account['cleartext_password']
  end

  test 'return decrypted account' do
    login_as(:bob)
    team = teams(:team1)
    group = groups(:group1)
    account = accounts(:account1)

    xhr :get, :show, team_id: team, group_id: group, id: account
    account = JSON.parse(response.body)['data']['account']

    assert_equal 'account1', account['accountname']
    assert_equal 'test', account['cleartext_username']
    assert_equal 'password', account['cleartext_password']
  end
end
