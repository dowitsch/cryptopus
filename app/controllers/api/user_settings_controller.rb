# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

class Api::UserSettingsController < ApiController

  def toggle_api
    user = User.find(params[:user_setting_id])
    user.toggle_api(current_user, session[:private_key])

    toggle_way = user.api_is_activated? ? 'activated' : 'deactivated'
    add_info(t("flashes.api.user_settings.toggle.#{toggle_way}"))
    render_json ''
  end

end
