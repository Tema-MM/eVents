class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update]
  before_action :require_admin, only: [:admin_dashboard, :new, :create, :edit, :update]

  def index
    if params[:query].present?
      query = "%#{params[:query].downcase}%"
      @events = Event.where(
        "LOWER(name) LIKE ? OR LOWER(venue) LIKE ? OR LOWER(date::text) LIKE ?",
        query, query, query
      )
    else
      @events = Event.all
    end
  end

  def show
  end

  def all
    @events = Event.all
  end

  def admin_dashboard
    @events = Event.all
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to admin_dashboard_events_path, notice: "Event was successfully created.", status: :see_other
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to admin_dashboard_events_path, notice: "Event was successfully updated.", status: :see_other
    else
      render :edit
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :date, :venue, :price, :tickets_available, :image)
  end
end