# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::TeamsControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper

  test 'destroy team' do
    login_as(:admin)
    team = Fabricate(:private_team)

    assert_difference('Team.count', -1) do
      delete :destroy, id: team.id
    end
    assert_not Teammember.where(team_id: team.id).present?, 'teammembers should be removed'
  end

  test 'returns last teammember teams' do
    login_as(:admin)

    soloteam = Fabricate(:private_team)
    user = soloteam.teammembers.first.user

    get :last_teammember_teams, user_id: user.id
    team = JSON.parse(response.body)['data']['teams'][0]


    assert_equal soloteam.id, team['id']
    assert_equal soloteam.name, team['name']
    assert_equal soloteam.description, team['description']
  end

  test 'cannot delete team if not admin' do
    login_as(:bob)
    soloteam = Fabricate(:private_team)
    user = soloteam.teammembers.first.user

    response = delete :destroy, id: soloteam.id

    error_message = JSON.parse(response.body)['messages']['errors'][0]

    assert_equal 'Access denied', error_message
    assert user.last_teammember_teams.present?
  end


  test 'cannot show last teammember teams if not admin' do
    login_as(:bob)
    soloteam = Fabricate(:private_team)
    user = User.find(soloteam.teammembers.first.user_id)

    response = get :last_teammember_teams, user_id: user.id

    error_message = JSON.parse(response.body)['messages']['errors'][0]

    assert_equal 'Access denied', error_message
  end

  test 'listing all teams' do
      login_as(:bob)

      xhr :get, :index

      team1 = JSON.parse(response.body)['data']['teams'][0]['name']
      team2 = JSON.parse(response.body)['data']['teams'][1]['name']
      assert_equal team1, 'team1'
      assert_equal team2, 'team2'
  end

  test 'listing all teams with api authentication' do
    api_key = "b5769035c051b99d1d45b0b89c746efc4e43b9f04668ea191bdde2373352baeb92427b9d354198c2"
    api_id = users('alice').apikey.id

    xhr :get, :index, api_key: api_key, api_id: api_id

    team1 = JSON.parse(response.body)['data']['teams'][0]['name']
    assert_equal team1, 'team1'
  end
end
