# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::Team::GroupsControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper

  test 'listing all groups of a choosen team' do
    login_as(:bob)
    team = teams(:team1)

    xhr :get, :index, team_id: team
    groups = JSON.parse(response.body)['data']['groups'][0]['name']

    assert_equal groups, 'group1'
  end

  test 'listing all groups of a choosen team with api authentication' do
    team = teams(:team1)

    xhr :get, :index, team_id: team, api_key: api_key_alice, api_id: api_id('alice')
    groups = JSON.parse(response.body)['data']['groups'][0]['name']

    assert_equal groups, 'group1'
  end
end
