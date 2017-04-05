class UserSettingsController < ApplicationController
  def index
  end

  def unlock_api
    User.find(params[:user_setting_id]).unlock
    redirect_to action: 'index'
  end
end
