class User::ApiKey < User
  belongs_to :origin_user, class_name: 'User', foreign_key: :origin_user_id

  def create_api_key(user_id)
    apikey = User::ApiKey.new
    apikey.origin_person_id = user_id
    apikey.api_key =
      require 'pry'; binding.pry
  end
end
