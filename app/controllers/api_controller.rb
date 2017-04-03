# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class ApiController < ApplicationController



  def render_json(data = nil)
    data = ActiveModelSerializers::SerializableResource.new(data).as_json
    render status: response_status, json: { data: data, messages: messages }
  end

  protected

  def add_error(msg)
    messages[:errors] << msg
  end

  def add_info(msg)
    messages[:info] << msg
  end

  def team
    @team ||= ::Team.find(params[:team_id])
  end


  def api_user
    @api_user ||= User.find(params['api_id'])
  end


  private

  def authorize
    if params[:api_key] || params[:api_id]
      if !authenticated?
        render status: :unauthorized, json: { messages: messages }
        return
      end
    else
      super
    end
  end

  def authenticated?
    api_id = params[:api_id]
    api_key = params[:api_key]

    api_user = User.find(api_id) if api_id.present?

    if api_user
      authenticate_api_user(api_id, api_key)
    else
      return false
    end
  end

  def authenticate_api_user(api_id, api_key)
    authenticator = Authentication::UserAuthenticator.new(params)

    if authenticator.api_key_auth!
      add_info 'Authenticated'
      return true
    else
      add_error 'Wrong API-ID or API-Key'
      return false
    end
  end

  def refuse_if_not_teammember
    team_id = params[:team_id]
    return if team_id.nil?
    team = Team.find(team_id)
    return if team.teammember?(api_user.id)
    add_error 'No Access to Team'
    render_json
    return
  end

  def messages
    @messages ||=
      { errors: [], info: [] }
  end

  def response_status
    @response_status ? @response_status : success_or_error
  end

  def success_or_error
    messages[:errors].present? ? :internal_server_error : nil
  end

end
