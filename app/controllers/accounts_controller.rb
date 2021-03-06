# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'ldap_tools'

class AccountsController < ApplicationController
  before_filter :group
  helper_method :team

  # GET /teams/1/groups/1/accounts
  def index
    accounts_breadcrumbs

    @accounts = @group.accounts.all

    respond_to do |format|
      format.html # index.html.haml
    end
  end

  # GET /teams/1/groups/1/accounts/1
  def show
    @account = Account.find(params[:id])
    @items = @account.items.load

    accounts_breadcrumbs

    @account.decrypt(plaintext_team_password(team))

    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # GET /teams/1/groups/1/accounts/new
  def new
    @account = @group.accounts.new

    respond_to do |format|
      format.html # new.html.haml
    end
  end

  # POST /teams/1/groups/1/accounts
  def create
    @account = @group.accounts.new(account_params)

    @account.encrypt(plaintext_team_password(team))

    respond_to do |format|
      if @account.save
        flash[:notice] = t('flashes.accounts.created')
        format.html { redirect_to team_group_accounts_url(team, @group) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # GET /teams/1/groups/1/accounts/1/edit
  def edit
    @account = @group.accounts.find(params[:id])
    @groups = team.groups.all

    accounts_breadcrumbs

    @account.decrypt(plaintext_team_password(team))

    respond_to do |format|
      format.html # edit.html.haml
    end
  end

  # PUT /teams/1/groups/1/accounts/1
  def update
    @account = @group.accounts.find(params[:id])
    @account.attributes = account_params

    @account.encrypt(plaintext_team_password(team))
    respond_to do |format|
      if @account.save
        flash[:notice] = t('flashes.accounts.updated')
        format.html { redirect_to team_group_accounts_url(team, @group) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /teams/1/groups/1/accounts/1
  def destroy
    @account = @group.accounts.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to team_group_accounts_url(team, @group) }
    end
  end

  # PUT /teams/1/groups/1/accounts/1/move
  def move
    @account = Account.find(params[:account_id])
    respond_to do |format|
      target_group = Group.find(account_params[:group_id])
      if account_move_handler.move(target_group)
        flash[:notice] = t('flashes.accounts.moved')
        format.html { redirect_to team_group_accounts_url(team, @group) }
      else
        @items = @account.items.load
        flash[:error] = @account.errors.full_messages.join
        format.html { render action: 'show' }
      end
    end
  end

  private

  def account_params
    params.require(:account).permit(:accountname, :cleartext_username,
                                    :cleartext_password, :description, :group_id)
  end

  def group
    @group ||= team.groups.find(params[:group_id])
  end

  def accounts_breadcrumbs
    add_breadcrumb t('teams.title'), :teams_path
    add_breadcrumb team.label, :team_groups_path

    add_breadcrumb @group.label if action_name == 'index'

    if action_name == 'show' || action_name == 'edit'
      add_breadcrumb @group.label, :team_group_accounts_path
      add_breadcrumb @account.label
    end
  end

  def account_move_handler
    AccountMoveHandler.new(@account, session[:private_key], current_user)
  end
end
