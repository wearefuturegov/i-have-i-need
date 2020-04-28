# frozen_string_literal: true

class TriageController < ApplicationController
  include ParamsConcern

  before_action :set_contact, only: %i[edit update]

  def edit
    @edit_contact_id = @contact.id
    @contact_needs = if session[:triage] && session[:triage][:contact_id] == @contact.id
                       @contact.assign_attributes(session[:triage][:contact_params])
                       ContactNeeds.new(session[:triage][:contact_needs_params])
                     else
                       create_contact_needs
                     end
  end

  def update
    if params.require(:discard_draft) == 'true'
      session[:triage] = nil
      redirect_to contact_path(@contact.id), notice: 'Draft triage discarded.'
    elsif params.require(:save_for_later) == 'true'
      save_for_later(@contact.id, contact_params, contact_needs_params)
      redirect_to new_contact_path, notice: 'Triage temporarily saved.'
    else
      apply_update
    end
  rescue ActiveRecord::StaleObjectError
    flash[:alert] = STALE_ERROR_MESSAGE
    render :edit
  end

  private

  # rubocop:disable Metrics/AbcSize
  def apply_update
    @contact.assign_attributes(
      any_dietary_requirements: contact_params[:any_dietary_requirements],
      dietary_details: contact_params[:dietary_details],
      eligible_for_free_prescriptions: contact_params[:eligible_for_free_prescriptions],
      cooking_facilities: contact_params[:cooking_facilities]
    )
    @contact_needs = ContactNeeds.new(contact_needs_params)
    @contact_needs.valid?
    @contact.valid?

    render(:edit) && return if @contact.errors.any? || @contact_needs.errors.any? || !@contact.save

    ContactChannel.broadcast_to(@contact, { userEmail: current_user.email, type: 'CHANGED' })
    NeedsCreator.create_needs(@contact, contact_needs_params['needs_list'], contact_needs_params['other_need'])
    session[:triage] = nil
    redirect_to contact_path(@contact.id), notice: 'Contact was successfully updated.'
  end
  # rubocop:enable Metrics/AbcSize

  def save_for_later(contact_id, contact_params, contact_needs_params)
    session[:triage] = {
      contact_id: contact_id,
      contact_params: contact_params,
      contact_needs_params: contact_needs_params
    }
  end

  def set_contact
    @contact = Contact.find(params[:contact_id])
    authorize(@contact, :update?)
  end

  def contact_params
    params.require(:contact).permit(:any_dietary_requirements, :dietary_details,
                                    :cooking_facilities, :eligible_for_free_prescriptions, :lock_version,
                                    :share_data_flag, :channel)
  end

  def contact_needs_params
    params.require(:contact_needs).permit!
  end

  def create_contact_needs
    contact_model = ContactNeeds.new
    contact_model.needs_list = Need.categories_for_triage.each_with_index.map do |(label, _slug), index|
      need = {
        name: label,
        active: false
      }
      if label == 'Phone triage'
        need[:active] =
          need[:start_on] = (Date.today + 6.days).strftime('%d/%m/%y')
      end
      [index.to_s, need]
    end.to_h
    contact_model
  end

  def submitted_value(need_type)
    contact_needs_params[:needs_list].values.find { |k| k[:name] == need_type }
  end
end
