class ContactChannel < ApplicationCable::Channel
  def subscribed
    stream_from "contact_id_#{params[:id]}"
  end

  def viewing(contact_id)
    ActionCable.server.broadcast("contact_id_#{contact_id['contact_id']}", current_user.email)
  end
end