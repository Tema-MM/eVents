class EventsController < ApplicationController
  before_action :set_event, only: [:edit, :update]
  before_action :require_admin, only: [:admin_dashboard, :new, :create, :edit, :update]

  def index
    # Public listing: use external API
    begin
      api = EventsApi.new
      events = api.list_events
      # Optional simple query filter on the client if provided
      if params[:query].present?
        q = params[:query].to_s.downcase
        events = events.select do |e|
          [e["name"], e["venue"], e["date"].to_s].compact.any? { |v| v.to_s.downcase.include?(q) }
        end
        # Limit homepage results under a query to keep carousel within bounds
        events = events.first(12)
      end
      # Limit results for homepage only when no query (limit before mapping to reduce work)
      events = events.first(6) if params[:query].blank?
      @events = events.map { |h| ApiEventMapper.from_hash(h) }
    rescue => e
      # Fallback to local DB with a limit
      flash.now[:alert] = "Unable to load events from API"
      scope = Event.order(created_at: :desc)
      if params[:query].present?
        # Case-insensitive substring search using ILIKE to enable trigram index usage
        q = "%#{params[:query]}%"
        scope = scope.where("name ILIKE ? OR venue ILIKE ?", q, q)
        # Apply simple pagination to cap result set size
        page = params[:page].to_i
        page = 1 if page < 1
        per_page = params[:per_page].to_i
        per_page = 30 if per_page <= 0
        per_page = 100 if per_page > 100
        @events = scope.offset((page - 1) * per_page).limit(per_page).to_a
        # Additionally cap homepage carousel to 12 items
        @events = @events.first(12)
      else
        @events = scope.limit(6).to_a
      end
    end
  end

  def show
    # Public detail: use external API
    begin
      api = EventsApi.new
      data = api.get_event(params[:id])
      @event = ApiEventMapper.from_hash(data)
    rescue => e
      # Fallback to local DB record if present
      begin
        record = Event.find(params[:id])
        @event = ApiEventMapper.from_hash({
          id: record.id,
          name: record.name,
          date: record.date,
          venue: record.venue,
          price: record.price,
          tickets_available: record.tickets_available
        })
      rescue ActiveRecord::RecordNotFound
        redirect_to root_path, alert: "Unable to load event" and return
      end
    end
  end

  def all
    # Paginated list to avoid overloading the page
    scope_name = params[:scope].presence || "upcoming"
    base_scope = case scope_name
                 when "past"
                   Event.where("date < ?", Date.today).order(date: :desc)
                 else
                   Event.where("date >= ?", Date.today).order(date: :asc)
                 end

    # Optional query filter for full results page
    if params[:query].present?
      q = "%#{params[:query]}%"
      base_scope = base_scope.where("name ILIKE ? OR venue ILIKE ?", q, q)
    end

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @per_page = params[:per_page].to_i
    @per_page = 30 if @per_page <= 0
    @per_page = 100 if @per_page > 100

    @total_count = base_scope.count
    @total_pages = (@total_count.to_f / @per_page).ceil

    @events = base_scope.offset((@page - 1) * @per_page).limit(@per_page).to_a
    @scope = scope_name
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