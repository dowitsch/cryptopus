# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class Api::Team::Group::AccountsController < ApiController

  skip_before_filter :verify_authenticity_token

  before_filter :group

  def index
    render_json @group.accounts.all.includes([:group])
  end

  def show
    account = Account.includes(group: [:team]).find(params['id'])
    account.decrypt(plaintext_team_password(team))
    render_json account
  end

  def update
    @account = @group.accounts.find(params[:id])
    @account.attributes = account_params

    @account.encrypt(plaintext_team_password(team))
    if @account.save
      add_info('Account has been updated')
      render_json @account
    else
      add_error('Account could not be saved')
      render_json
    end
  end

  def create
    group = Group.find(params['group_id'])
    account = group.accounts.new(account_params)

    account.encrypt(plaintext_team_password(team))

    if account.save
      add_info('Account created!')
      render_json @account
    else
      add_error('Error while creating the account')
      render_json
    end
  end

  def destroy
    account = Account.find(params['id'])
    account.destroy
    add_info('Account has been deleted')
    render_json
  end

  private

  def account_params
    params.require(:account).permit(:accountname, :cleartext_username, :group_id,
                                    :cleartext_password, :description, :identifier)
  end

  def group
    begin
      @group ||= team.groups.find(params[:group_id])
    rescue
      add_error('Group not found in this team')
      render_json
      return
    end
  end

end
