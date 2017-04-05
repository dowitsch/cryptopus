# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class Api::TeamsController < ApiController
  before_filter :admin_only, except: :index

  def index
    if current_user
      teams = current_user.teams
    else
      teams = api_user.teams
    end
    render_json teams
  end

  def last_teammember_teams
    teams = user.last_teammember_teams
    render_json teams
  end

  def destroy
    team.destroy
    render_json ''
  end

  protected

  def admin_only
    unless current_user.admin?
      add_error t('flashes.admin.admin.no_access')
      render_json && return
    end
  end

  private

  def user
    @user ||= User.find(params['user_id'])
  end

  def team
    @team ||= Team.find(params['id'])
  end
end
