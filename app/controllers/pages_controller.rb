# Create app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def events
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
    # No month filter to show all events for the year
    @events = holidays.select do |h|
      date_str = h["date"]
      next false unless date_str.present?
      Date.parse(date_str) rescue false
    end
  end
end