# frozen_string_literal: true

class NeedsController < ApplicationController
  include ParamsConcern
  before_action :set_need, only: %i[show edit update]
  before_action :set_contact, only: %i[new create]

  helper_method :get_param

  def index
    @params = params.permit(:assigned_to, :status, :category, :page, :order_dir, :order, :commit, :is_urgent, :created_by_me)
    @needs = if @params[:created_by_me] == 'true'
               @assigned_to_options = {}
               Need.created_by(current_user.id).filter_by_assigned_to('Unassigned')
             else
               @assigned_to_options = construct_assigned_to_options
               policy_scope(Need).started
             end

    @needs = @needs.filter_and_sort(@params.slice(:category, :assigned_to, :status, :is_urgent), @params.slice(:order, :order_dir))
    @needs = @needs.page(params[:page]) unless request.format == 'csv'
    respond_to do |format|
      format.html
      format.csv do
        authorize(Need, :export?)
        send_data @needs.to_csv, filename: "needs-#{Date.today}.csv"
      end
    end
  end

  def deleted_needs
    @params = params.permit(:category, :page, :order_dir, :order, :commit, :deleted_at)
    @needs = policy_scope(Need).deleted
                               .filter_and_sort(@params.slice(:category, :deleted_at), @params.slice(:order, :order_dir))
    @needs = @needs.page(params[:page])
  end

  def deleted_notes
    @params = params.permit(:category, :page, :order_dir, :order, :commit, :deleted_at)
    @notes = policy_scope(Note).deleted
                               .filter_need_not_destroyed
                               .filter_and_sort(@params.slice(:category, :deleted_at), @params.slice(:order, :order_dir))

    @notes = @notes.page(params[:page])
  end

  def destroy
    if params[:note_only] == 'true'
      delete_note params
    else
      delete_need params
    end
  rescue ActiveRecord::StaleObjectError
    flash[:alert] = STALE_ERROR_MESSAGE
    @assigned_to_options = construct_assigned_to_options
    @delete_prompt = get_delete_prompt @need
    render :show
  end

  def show
    @need.notes.order(created_at: :desc)
    populate_page_data
  end

  def edit
    @delete_prompt = get_delete_prompt @need
  end

  def update
    if @need.update(need_params)
      notify_new_assignee(@need)
      redirect_to need_path(@need), notice: 'Record successfully updated.'
    else
      populate_page_data
      render :show
    end
  rescue ActiveRecord::StaleObjectError
    flash[:alert] = STALE_ERROR_MESSAGE
    populate_page_data
    render :show
  end

  def bulk_action
    for_update = JSON.parse(params[:for_update])
    for_update.each do |obj|
      need = Need.find(obj['need_id'])
      authorize(need)
      to_update = {}
      to_update[:assigned_to] = assigned_to_me(obj['assigned_to']) if obj.key?('assigned_to')
      to_update[:status] = obj['status'] if obj.key?('status')
      need.update! to_update
    end
    render json: { status: 'ok' }
  end

  def restore_need
    need = policy_scope(Need).deleted.where(id: params[:id])
    if need.exists?
      need_name = need.first.category
      Rails.logger.info("Restored need '#{params[:id]}'")
      need.first.restore(recursive: true)
      redirect_to deleted_needs_path(order: 'deleted_at', order_dir: 'DESC'),
                  notice: "Restored '#{need_name}' see <a href='#{need_path(need.first.id)}'>here</a>"
    else
      redirect_to deleted_needs_path(order: 'deleted_at', order_dir: 'DESC'), alert: 'Could not restore record.'
    end
  end

  def restore_note
    note = policy_scope(Note).deleted.where(id: params[:id])
    if note.exists?
      note_name = note.first.category
      Rails.logger.info("Restored note '#{params[:id]}'")
      note.first.restore
      redirect_to deleted_notes_path(order: 'deleted_at', order_dir: 'DESC'),
                  notice: "Restored '#{note_name}' see <a href='#{need_path(note.first.need_id)}'>here</a>"
    else
      redirect_to deleted_notes_path(order: 'deleted_at', order_dir: 'DESC'), alert: 'Could not restore record.'
    end
  end

  private

  def delete_note(params)
    note = Note.find(params[:id])
    note.destroy

    @need = Need.find(params[:need_id])
    populate_page_data

    redirect_to need_path(@need)
  end

  def delete_need(params)
    need = Need.find(params[:id])
    need_name = need.category

    if need.destroy
      redirect_to contact_path(need.contact_id), notice: "'#{need_name}' was successfully deleted."
    else
      populate_page_data
      render :show
    end
  end

  def populate_page_data
    @assigned_to_options = construct_assigned_to_options
    @delete_prompt = get_delete_prompt @need
  end

  def get_delete_prompt(need)
    "Only Delete this #{need.category} if you created it by mistake. If it is cancelled, blocked or completed, please update the status instead.  Click OK to delete"
  end

  def set_need
    # handle browsing back to a need that has been deleted
    @need = Need.with_deleted.where(id: params[:id]).first
    redirect_to contact_path(@need.contact_id) if @need.deleted_at

    @contact = @need.contact
    authorize(@need)
    authorize(@contact, :show?)
  end

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def need_params
    permit_need_params = params.require(:need).permit(:id, :name, :status, :assigned_to, :category, :is_urgent, :lock_version)
    permit_need_params[:assigned_to] = assigned_to_me(permit_need_params[:assigned_to])
    permit_need_params
  end

  def assigned_to_me(assigned_to)
    assigned_to = "user-#{current_user.id}" if assigned_to == 'assigned-to-me'
    assigned_to
  end

  def construct_assigned_to_options
    roles = Role.all.order(:name)
    users = User.all.order(:first_name, :last_name)

    {
      'Teams' => roles.map { |role| [role.name, "role-#{role.id}"] },
      'Users' => users.map { |user| [user.name_or_email, "user-#{user.id}"] }
    }
  end

  def notify_new_assignee(need)
    if need.saved_change_to_user_id? || need.saved_change_to_role_id?
      if need.user_id?
        user = User.find(need.user_id)
        NeedAssigneeMailer.send_user_assigned_need_email(user.email, need_url(need)).deliver
      elsif need.role_id?
        role_user_emails = User.joins(:roles).where(roles: { id: need.role_id }).select(:email)
        role_user_emails.each do |role_member_email|
          NeedAssigneeMailer.send_role_assigned_need_email(role_member_email, need.role.name, need_url(need)).deliver
        end
      end
    end
  end
end
