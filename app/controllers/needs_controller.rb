class NeedsController < ApplicationController
  include ParamsConcern
  before_action :set_need, only: [:show, :edit, :update]
  before_action :set_contact, only: [:new, :create]

  helper_method :get_param

  def index
    @params = params.permit(:user_id, :status, :category, :page, :order_dir, :order, :commit)
    @users = User.all
    @needs = Need.includes(:contact, :user)
    @needs = @needs.filter_by_category(params[:category]) if params[:category].present?
    @needs = @needs.filter_by_user_id(params[:user_id]) if params[:user_id].present?
    @needs = @needs.filter_by_status(params[:status]) if params[:status].present?

    if params[:order].present? && params[:order_dir].present?
      sort_column = Need.column_names.include?(params[:order]) ? params[:order] : 'created_at'
      sort_order = %w(asc desc).include?(params[:order_dir].downcase) ? params[:order_dir] : 'desc'
      @needs = @needs.order("#{sort_column} #{sort_order}")
    else
      @needs = @needs.order(created_at: :desc)
    end

    @needs = @needs.page(params[:page])
  end

  def show
  end

  def new
    @needs = Needs.new
  end

  def create
    needs_params["needs_list"].each do |_, value|
      if value["active"] == "true"
        need_category = value["name"].humanize.downcase
        need_description = value["description"]
        if need_description.blank?
          need_description = "#{@contact.name} needs #{need_category}"
        end

        @contact.needs.build(category: need_category, name: need_description, due_by: DateTime.now + 7.days).save
      end
    end

    if needs_params["other_need"]
      @contact.needs.build(category: "other", name: needs_params["other_need"], due_by: DateTime.now + 7.days).save
    end

    redirect_to controller: :contacts, action: :show_needs, id: @contact.id
  end

  def edit
    @users = User.all
  end

  def update
    if @need.update(need_params)
      redirect_to need_path(@need), notice: 'Need was successfully updated.'
    else
      @users = User.all
      render :edit
    end
  end

  private

  def set_need
    @need = Need.find(params[:id])
    @contact = @need.contact
  end

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def need_params
    params.require(:need).permit(:name, :status, :user_id, :category)
  end

  def needs_params
    params.require(:needs).permit!
  end
end
