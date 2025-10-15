class EventsApi
  include HTTParty
  base_uri ENV["EVENTS_API_BASE_URL"] if ENV["EVENTS_API_BASE_URL"].present?

  def initialize(api_key: ENV["EVENTS_API_KEY"])
    @headers = {}
    @headers["Authorization"] = "Bearer #{api_key}" if api_key.present?
    @headers["Content-Type"] = "application/json"
    @headers["Accept"] = "application/json"
  end

  def list_events
    raise "EVENTS_API_BASE_URL not set" unless self.class.base_uri
    Rails.cache.fetch("events_api:list_events", expires_in: 5.minutes) do
      response = self.class.get("/events", headers: @headers, timeout: 5)
      raise "Events API error: #{response.code}" unless response.success?
      response.parsed_response
    end
  end

  def get_event(id)
    raise "EVENTS_API_BASE_URL not set" unless self.class.base_uri
    Rails.cache.fetch("events_api:get_event:#{id}", expires_in: 10.minutes) do
      response = self.class.get("/events/#{id}", headers: @headers, timeout: 5)
      raise "Events API error: #{response.code}" unless response.success?
      response.parsed_response
    end
  end

  def tickets_for_event(id)
    raise "EVENTS_API_BASE_URL not set" unless self.class.base_uri
    response = self.class.get("/events/#{id}/tickets", headers: @headers, timeout: 5)
    raise "Events API error: #{response.code}" unless response.success?
    response.parsed_response
  end
end


