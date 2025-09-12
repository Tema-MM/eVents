class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def show
    @event_date = params[:id]
    # Fetch event for display
    year = Time.now.year
    response = HTTParty.get(
      "https://holidays-by-api-ninjas.p.rapidapi.com/v1/holidays",
      query: { country: "us", year: year },
      headers: {
        "x-rapidapi-key" => "768e4661b0msh1c1f488766a690ep12fd07jsn33fd5d92b2a4",
        "x-rapidapi-host" => "holidays-by-api-ninjas.p.rapidapi.com"
      }
    )
    holidays = JSON.parse(response.body)
    @event = holidays.find { |h| h["date"] == @event_date }
    if @event.nil?
      redirect_to root_path, alert: "Event not found"
    end
  end
end