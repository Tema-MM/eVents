# Seed the database with 10 mock social events
# Update db/seeds.rb
Event.create!([
  { name: "Summer Music Festival", date: "2025-08-30", venue: "City Park", price: 50.00, tickets_available: 200 },
  { name: "Art Exhibition Gala", date: "2025-09-05", venue: "Art Gallery Downtown", price: 30.00, tickets_available: 150 },
  { name: "Charity Run Event", date: "2025-09-10", venue: "Central Park", price: 20.00, tickets_available: 300 },
  { name: "Food Truck Festival", date: "2025-09-15", venue: "Riverfront Plaza", price: 15.00, tickets_available: 0 }, # Out of stock
  { name: "Comedy Night Show", date: "2025-09-20", venue: "Local Theater", price: 25.00, tickets_available: 100 },
  { name: "Tech Meetup", date: "2025-09-25", venue: "Innovation Hub", price: 40.00, tickets_available: 120 },
  { name: "Yoga Retreat Day", date: "2025-09-30", venue: "Beachfront Resort", price: 35.00, tickets_available: 80 },
  { name: "Book Club Gathering", date: "2025-10-05", venue: "Library Cafe", price: 10.00, tickets_available: 50 },
  { name: "Dance Party Night", date: "2025-10-10", venue: "Nightclub Downtown", price: 45.00, tickets_available: 180 },
  { name: "Film Screening Event", date: "2025-10-15", venue: "Cinema Hall", price: 25.00, tickets_available: 140 }
])

# Stress test: bulk-generate events unless already present
if ENV["STRESS_SEED"].present?
  require "securerandom"
  require "date"
  total = (ENV["STRESS_SEED"].to_i > 0 ? ENV["STRESS_SEED"].to_i : 2000)
  puts "Generating #{total} random events..."
  venues = ["City Park", "Art Gallery Downtown", "Central Park", "Riverfront Plaza", "Local Theater", "Innovation Hub", "Beachfront Resort", "Library Cafe", "Nightclub Downtown", "Cinema Hall"]
  names = ["Music Fest", "Art Gala", "Charity Run", "Food Trucks", "Comedy Night", "Tech Meetup", "Yoga Retreat", "Book Club", "Dance Party", "Film Screening"]
  now = Date.today

  batch = []
  total.times do |i|
    name = "#{names.sample} #{SecureRandom.hex(2)}"
    date = now + rand(-90..180)
    venue = venues.sample
    price = rand(5..100)
    tickets = rand(0..500)
    batch << { name: name, date: date, venue: venue, price: price, tickets_available: tickets, created_at: Time.now, updated_at: Time.now }
    if batch.size >= 1000
      Event.insert_all(batch)
      batch.clear
    end
  end
  Event.insert_all(batch) if batch.any?
  puts "Done."
end
