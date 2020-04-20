# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def find_verified_user
      session_token = @request.session["passwordless_session_id--user"]
      session = Passwordless::Session.find(session_token)
      verified_user = User.find(session.authenticatable_id)
      if verified_user
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
