module UserSettingsHelper
  def change_api_access
    class_name = 'pull-right toggle-button-api'
    class_name += ' toggle-button-api-selected' if current_user.apikey.present?

    content_tag(:div, class: class_name, id: current_user.id) do
      content_tag(:button)
    end
  end

  def show_api_key
    content_tag(:p, current_user.apikey.decrypted_api_key(session[:private_key]))
  end
end
