require "test_helper"

class UserSettingsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_response :success
  end

end
