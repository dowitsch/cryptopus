# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class Api::Team::MembersControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper

  test 'returns team member candidates for new team' do
    login_as(:admin)
    team = Team.create(users(:admin), {name: 'foo'})

    xhr :get, :candidates, team_id: team

    candidates = JSON.parse(response.body)['data']['users']

    assert_equal 3, candidates.size
    assert candidates.any? {|c| c['label'] == 'Alice test' }, 'Alice should be candidate'
    assert candidates.any? {|c| c['label'] == 'Bob test' }, 'Bob should be candidate'
  end

  test 'returns team members for given team' do
    login_as(:admin)

    team = teams(:team1)
    teammembers(:team1_bob).destroy!

    xhr :get, :index, team_id: team

    members = JSON.parse(response.body)['data']['teammembers']

    assert_equal 4, members.size
    assert members.any? {|c| c['label'] == 'Alice test' }, 'Alice should be in team'
    assert members.any? {|c| c['label'] == 'Admin test' },  'Admin should be in team'
  end

  test 'creates new teammember for given team' do
    login_as(:admin)
    team = teams(:team1)
    user = Fabricate(:user)

    xhr :post, :create, team_id: team, user_id: user

    assert team.teammember?(user), 'User should be added to team'
  end

  test 'does not remove admin from non private team' do
    login_as(:alice)

    assert_raise do
      xhr :delete, :destroy, team_id: teams(:team1), id: users(:admin)
    end
  end

  test 'remove teammember from team' do
    login_as(:alice)
    assert_difference('Teammember.count', -1) do
      xhr :delete, :destroy, team_id: teams(:team1), id: users(:bob)
    end
  end
end
