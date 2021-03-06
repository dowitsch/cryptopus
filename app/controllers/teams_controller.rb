# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class TeamsController < ApplicationController
  before_filter :redirect_if_not_teammember_or_admin, except: [:index, :new, :create]
  before_filter :redirect_if_not_allowed_to_delete_team, only: [:destroy]
  helper_method :can_delete_team?, :team
  helper_method :team_has_permisson_for_api?, :team

  # GET /teams
  def index
    @teams = current_user.teams

    respond_to do |format|
      format.html # index.html.haml
    end
  end

  # GET /teams/new
  def new
    @team = Team.new

    respond_to do |format|
      format.html # new.html.haml
    end
  end

  # POST /teams
  def create
    respond_to do |format|
      team = Team.create(current_user, team_params)
      if team.valid?
        flash[:notice] = t('flashes.teams.created')
        format.html { redirect_to(teams_url) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # GET /teams/1/edit
  def edit
    add_breadcrumb t('teams.title'), :teams_path
    add_breadcrumb team.label
  end

  # PUT /teams/1
  def update
    api_permisson_handler(params['api'])
    respond_to do |format|
      if team.update_attributes(team_params)
        flash[:notice] = t('flashes.teams.updated')
        format.html { redirect_to(teams_url) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /teams/1
  def destroy
    team.destroy
    flash[:notice] = t('flashes.teams.deleted')
    redirect_to teams_path
  end

  private

  def team_params
    params.require(:team).permit(:name, :private, :description)
  end

  def redirect_if_not_teammember_or_admin
    return if team.teammember?(current_user.id) || current_user.admin?
    flash[:error] = 'You are not member of this team'
    redirect_to teams_path
  end

  def redirect_if_not_allowed_to_delete_team
    return if can_delete_team?(team)
    flash[:error] = t('flashes.teams.cannot_delete')
    redirect_to teams_path
  end

  def api_permisson_handler(teammember)
    if teammember == 'api' && !team.teammember?(current_user.apikey.id)
      decrypted_team_password = team.decrypt_team_password(current_user, session[:private_key])
      team.add_user(current_user.apikey, decrypted_team_password)
    elsif teammember.nil? && team.teammember?(current_user.apikey.id)
      team.remove_user(current_user.apikey)
    end
  end

  def can_delete_team?(_team)
    current_user.admin?
  end

  def team_has_permisson_for_api?
    team.teammember?(current_user.apikey.id)
  end

  def team
    @team ||= Team.find(params[:id])
  end
end
