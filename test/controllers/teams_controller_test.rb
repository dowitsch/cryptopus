# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'test_helper'

class TeamsControllerTest < ActionController::TestCase

  include ControllerTest::DefaultHelper


  test "alice deactivates and activates api access for team" do
    login_as(:alice)
    team = teams(:team1)
    alice = users(:alice)

    assert team.teammember?(alice.apikey)

    team_params = {name: team.name, description: team.description}

    put :update, id: team, api: nil, team: team_params

    team.reload

    assert_not team.teammember?(alice.apikey)


    put :update, id: team, api: 'api', team: team_params

    team.reload

    assert team.teammember?(alice.apikey)
  end

  test "alice cannot activates api for team she is not member" do
    login_as(:alice)
    team = teams(:team2)
    alice = users(:alice)

    assert_not team.teammember?(alice)
    assert_not team.teammember?(alice.apikey)

    team_params = {name: team.name, description: team.description}

    put :update, id: team, api: 'api', team: team_params

    team.reload

    assert_not team.teammember?(alice.apikey)
  end

  test "admin can delete team if in team" do
    login_as(:admin)

    assert_difference('Team.count', -1) do
      delete :destroy, id: teams(:team1).id
    end

    assert_redirected_to teams_path
    assert_match /deleted/, flash[:notice]
  end

  test "normal teammember cannot delete team" do
    login_as(:bob)

    assert_difference('Team.count', 0) do
      delete :destroy, id: teams(:team1).id
    end

    assert_redirected_to teams_path
    assert_match /Only admin/, flash[:error]
  end

  test "normal user cannot delete team if not in team" do
    login_as(:bob)

    teammembers(:team1_bob).delete

    assert_difference('Team.count', 0) do
      delete :destroy, id: teams(:team1).id
    end

    assert_redirected_to teams_path
    assert_match /not member/, flash[:error]
  end

  test "Admin can delete team if not in team" do
    login_as(:admin)

    teammembers(:team1_admin).delete

    assert_difference('Team.count', -1) do
      delete :destroy, id: teams(:team1).id
    end

    assert_redirected_to teams_path
    assert_match /deleted/, flash[:notice]
  end

  test 'bob has no delete button for teams' do
    login_as(:bob)
    get :index
    assert_select "a[href='/en/teams/#{teams(:team1).id}']", false, "Delete button should not exist"
  end

  test 'admin has delete button for teams' do
    login_as(:admin)
    get :index
    assert_select "a[href='/en/teams/#{teams(:team1).id}']"
  end

  test "user creates new team" do
    login_as(:bob)

    team_params = {name: 'foo', private: false, description: 'foo foo' }

    post :create, team: team_params

    assert_redirected_to teams_path

    team = Team.find_by(name: 'foo')
    assert_equal 3, team.teammembers.count
    user_ids = team.teammembers.pluck(:user_id)
    assert_includes user_ids, users(:bob).id
    assert_includes user_ids, users(:admin).id
    assert_not team.private?
    assert_equal 'foo foo', team.description
  end

  test "private cannot be enabled on existing team" do
    login_as(:alice)
    team = teams(:team1)

    assert_not team.private?

    update_params = { private: true }

    put :update, id: team.id, team: update_params

    team.reload

    assert_not team.private?
  end

  test "private cannot be disabled on existing team" do
    login_as(:alice)

    team_params = {name: 'foo', private: true}
    team = Team.create(users(:alice), team_params)

    update_params = { private: false }

    put :update, id: team, team: update_params

    team.reload

    assert team.private?
  end

  test 'show breadcrump path 2 if user is on edit of team' do
    login_as (:bob)

    team1 = teams(:team1)

    get :edit, id: team1

    assert_select '.breadcrumb', text: 'Teamsteam1'
    assert_select '.breadcrumb a', count: 1
    assert_select '.breadcrumb a', text: 'Teams'
    assert_select '.breadcrumb a', text: 'team1', count: 0
  end

  test 'should redirect if pending recryptrequest' do
    Recryptrequest.create(user_id: users(:bob).id).save

    login_as(:bob)

    get :index

    assert_redirected_to logout_login_path
    assert_match /recryption of your team passwords/, flash[:notice]
  end

  test 'redirects to login path if user has pending recryptrequests' do
    Recryptrequest.create(user_id: users(:bob).id)
    login_as(:bob)
    get :index
    assert_match /Wait for the recryption/, flash[:notice]
  end
end
