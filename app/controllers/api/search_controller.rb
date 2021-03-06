# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class Api::SearchController < ApiController

  def accounts
    term = params[:q]

    accounts = current_user.search_accounts(term)

    render_json accounts
  end

  def groups
    term = params[:q]
    render_json current_user.search_groups(term)
  end

  def teams
    term = params[:q]
    render_json current_user.search_teams(term)
  end

  def identify_account
    identifier = params[:identifier]

    account = api_user.identify_account(identifier)

    if account
      team = account.group.team
      account.decrypt(plaintext_team_password(team))
      render_json account
    else
      add_error('No Account with this identifier found')
      render_json
    end
  end

end
