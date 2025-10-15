class ApiEventMapper
  def self.from_hash(h)
    ApiEvent.new(
      id: h["id"] || h[:id],
      name: h["name"] || h[:name],
      date: (h["date"] || h[:date]),
      venue: (h["venue"] || h[:venue]),
      price: (h["price"] || h[:price]).to_f,
      tickets_available: (h["tickets_available"] || h[:tickets_available]).to_i
    )
  end
end


