# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::SearchControllerTest < ActionController::TestCase
  include ControllerTest::DefaultHelper

  test "should get error message if no account was found" do
    xhr :get, :identify_account, {identifier: 'wrongidentifier', api_id: api_id('alice'), api_key: api_key_alice}

    error = JSON.parse(response.body)['messages']['errors'][0]

    assert_equal 'No Account with this identifier found', error
  end

  test "should get account for matching identifier with api authentication" do
    xhr :get, :identify_account, {identifier: 'identifier1', api_id: api_id('alice'), api_key: api_key_alice}

    result_json = JSON.parse(response.body)['data']['account']

    account = accounts(:account1)
    group = account.group
    team = group.team

    assert_equal account.accountname, result_json['accountname']
    assert_equal account.id, result_json['id']
    assert_equal 'test', result_json['cleartext_username']
    assert_equal 'password', result_json['cleartext_password']

    assert_equal group.name, result_json['group']
    assert_equal group.id, result_json['group_id']

    assert_equal team.name, result_json['team']
    assert_equal team.id, result_json['team_id']
  end

  test "should get account for matching accountname without cleartext username / password" do
    login_as(:alice)
    xhr :get, :accounts, {'q' => 'acc'}

    result_json = JSON.parse(response.body)['data']['accounts'][0]

    account = accounts(:account1)
    group = account.group
    team = group.team

    assert_equal account.accountname, result_json['accountname']
    assert_equal account.id, result_json['id']
    assert_equal nil, result_json['cleartext_username']
    assert_equal nil, result_json['cleartext_password']

    assert_equal group.name, result_json['group']
    assert_equal group.id, result_json['group_id']

    assert_equal team.name, result_json['team']
    assert_equal team.id, result_json['team_id']
  end

  test "should get account for matching description without cleartext username / password" do
    login_as(:alice)
    xhr :get, :accounts, {'q' => 'des'}

    result_json = JSON.parse(response.body)['data']['accounts'][0]

    account = accounts(:account1)
    group = account.group
    team = group.team

    assert_equal account.accountname, result_json['accountname']
    assert_equal account.id, result_json['id']
    assert_equal nil, result_json['cleartext_username']
    assert_equal nil, result_json['cleartext_password']

    assert_equal group.name, result_json['group']
    assert_equal group.id, result_json['group_id']

    assert_equal team.name, result_json['team']
    assert_equal team.id, result_json['team_id']
  end

  test "should get group for search term" do
    login_as(:alice)
    xhr :get, :groups, {'q' => 'group'}

    result_json = JSON.parse(response.body)['data']['groups'][0]

    group = groups(:group1)

    assert_equal group.name, result_json['name']
    assert_equal group.id, result_json['id']
  end


  test "should get team for search term" do
    login_as(:alice)
    xhr :get, :teams, {'q' => 'team'}

    result_json = JSON.parse(response.body)['data']['teams'][0]

    team = teams(:team1)

    assert_equal team.name, result_json['name']
    assert_equal team.id, result_json['id']
  end
end
