module Authentication
  module Authenticators
    class ::ApiKey

      def initialize(params)
        @api_key = params[:api_key]
        @api_id = params[:api_id]
      end

      def params_present?
        @api_key.present? && @api_id.present?
      end

      def auth!
        user.authenticate(@api_key)
      end

      def user
        @user ||= find_user
      end

      private

      def find_user
        User.find(@api_id)
      end

    end
  end
end
