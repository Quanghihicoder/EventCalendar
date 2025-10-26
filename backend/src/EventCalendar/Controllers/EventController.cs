using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Threading.Tasks;
using System.Text.Json;

namespace EventCalendar.Controllers
{
    public class EventData
    {
        public List<Event> events { get; set; }
        public List<Venue> venues { get; set; }
    }

    public class Event
    {
        public int id { get; set; }
        public string name { get; set; }
        public string? description { get; set; }
        public string startDate { get; set; } 
        public int venueId { get; set; }
        public int? day { get; set; } 
    }

    public class Venue
    {
        public int id { get; set; }
        public string name { get; set; }
        public int capacity { get; set; }
        public string location { get; set; }
    }


    [ApiController]
    [Route("[controller]")]
    public class EventController : ControllerBase
    {
        private readonly HttpClient _httpClient;

        // Private dictionary mapping venue locations to IANA time zone IDs
        private static readonly Dictionary<string, string> venueTimeZones = new Dictionary<string, string>
        {
            // Europe
            { "London, UK", "Europe/London" },
            { "Paris, France", "Europe/Paris" },
            { "Berlin, Germany", "Europe/Berlin" },
            { "Madrid, Spain", "Europe/Madrid" },
            { "Rome, Italy", "Europe/Rome" },
            { "Amsterdam, Netherlands", "Europe/Amsterdam" },
            { "Zurich, Switzerland", "Europe/Zurich" },
            { "Stockholm, Sweden", "Europe/Stockholm" },
            { "Oslo, Norway", "Europe/Oslo" },
            { "Warsaw, Poland", "Europe/Warsaw" },
            { "Helsinki, Finland", "Europe/Helsinki" },
            { "Athens, Greece", "Europe/Athens" },

            // Asia-Pacific
            { "Sydney, Australia", "Australia/Sydney" },
            { "Melbourne, Australia", "Australia/Melbourne" },
            { "Brisbane, Australia", "Australia/Brisbane" },
            { "Perth, Australia", "Australia/Perth" },
            { "Auckland, New Zealand", "Pacific/Auckland" },
            { "Wellington, New Zealand", "Pacific/Auckland" },
            { "Singapore", "Asia/Singapore" },
            { "Hong Kong", "Asia/Hong_Kong" },
            { "Tokyo, Japan", "Asia/Tokyo" },
            { "Seoul, South Korea", "Asia/Seoul" },
            { "Bangkok, Thailand", "Asia/Bangkok" },
            { "Manila, Philippines", "Asia/Manila" },
            { "Kuala Lumpur, Malaysia", "Asia/Kuala_Lumpur" },
            { "Jakarta, Indonesia", "Asia/Jakarta" },
            { "Beijing, China", "Asia/Shanghai" },
            { "Shanghai, China", "Asia/Shanghai" },
            { "Taipei, Taiwan", "Asia/Taipei" },
            { "Mumbai, India", "Asia/Kolkata" },
            { "New Delhi, India", "Asia/Kolkata" },
            { "Dubai, UAE", "Asia/Dubai" },

            // North America
            { "New York, USA", "America/New_York" },
            { "Washington DC, USA", "America/New_York" },
            { "Chicago, USA", "America/Chicago" },
            { "Denver, USA", "America/Denver" },
            { "Los Angeles, USA", "America/Los_Angeles" },
            { "San Francisco, USA", "America/Los_Angeles" },
            { "Vancouver, Canada", "America/Vancouver" },
            { "Toronto, Canada", "America/Toronto" },
            { "Montreal, Canada", "America/Toronto" },
            { "Mexico City, Mexico", "America/Mexico_City" },

            // South America
            { "São Paulo, Brazil", "America/Sao_Paulo" },
            { "Buenos Aires, Argentina", "America/Argentina/Buenos_Aires" },
            { "Santiago, Chile", "America/Santiago" },
            { "Bogotá, Colombia", "America/Bogota" },
            { "Lima, Peru", "America/Lima" },

            // Middle East & Africa
            { "Cairo, Egypt", "Africa/Cairo" },
            { "Johannesburg, South Africa", "Africa/Johannesburg" },
            { "Nairobi, Kenya", "Africa/Nairobi" },
            { "Riyadh, Saudi Arabia", "Asia/Riyadh" },
            { "Tel Aviv, Israel", "Asia/Jerusalem" },
            { "Doha, Qatar", "Asia/Qatar" },

            // Default or special
            { "TEG Metaverse", "UTC" },
            { "Online", "UTC" },
            { "Virtual", "UTC" }
        };

        private static string ConvertUtcStringToLocalTime(string utcIsoString, string venueLocation)
         {
            if (!DateTime.TryParse(utcIsoString, null, System.Globalization.DateTimeStyles.AdjustToUniversal, out var utcTime))
                throw new ArgumentException("Invalid UTC date string.");

            // Default to UTC if venue not found
            if (!venueTimeZones.TryGetValue(venueLocation, out var tzId))
                tzId = "UTC";

            TimeZoneInfo timeZone = TimeZoneInfo.FindSystemTimeZoneById(tzId);
            DateTime localTime = TimeZoneInfo.ConvertTimeFromUtc(utcTime, timeZone);

            return localTime.ToString("yyyy-MM-dd|HH:mm");
        }

        public EventController(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

    
        [HttpGet]
        public async Task<IActionResult> GetEvents(int month, int year)
        {
            string url = "https://teg-coding-challenge.s3.ap-southeast-2.amazonaws.com/events/event-data.json";

            // Fetch JSON
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, "Failed to fetch data");

            var json = await response.Content.ReadAsStringAsync();

            // Deserialize JSON
            var data = JsonSerializer.Deserialize<EventData>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (data == null)
                return Ok(new { events = new List<Event>(), venues = new List<Venue>() });

            // Convert event startDate from UTC to local time using venue location
            foreach (var e in data.events)
            {
                var venue = data.venues.FirstOrDefault(v => v.id == e.venueId);
                if (venue != null)
                {
                    e.startDate = ConvertUtcStringToLocalTime(e.startDate, venue.location);
                }
                else
                {
                    // Invalid venue (mark to skip)
                    e.startDate = null;
                }
            }

            var firstOfMonth = new DateTime(year, month, 1);
            var lastOfMonth = firstOfMonth.AddMonths(1).AddDays(-1);

            int daysInMonth = (lastOfMonth - firstOfMonth).Days + 1;
            int startWeekday = (int)firstOfMonth.DayOfWeek; // 0 = Sunday

            // Calendar start: go back to previous Sunday
            var calendarStart = firstOfMonth.AddDays(-startWeekday);

            // Calendar end: fill full weeks
            int totalCells = ((daysInMonth + startWeekday + 6) / 7) * 7;
            var calendarEnd = calendarStart.AddDays(totalCells - 1);

            // Filter events within calendar range and calculate day
            var filteredEvents = data.events
                .Where(e => !string.IsNullOrEmpty(e.startDate) &&
                            DateTime.TryParse(e.startDate.Split('|')[0], out var date) &&
                            date >= calendarStart && date <= calendarEnd)
                .Select(e =>
                {
                    DateTime.TryParse(e.startDate.Split('|')[0], out var date);

                    // Last month day will be -4,-3,-2,-1

                    int day;
                    if (date < firstOfMonth) // previous month
                        day = -((firstOfMonth - date).Days);
                    else if (date > lastOfMonth) // next month
                        day = daysInMonth + (date - lastOfMonth).Days;
                    else
                        day = date.Day; // current month

                    e.day = day;
                    return e;
                })
                .OrderBy(e => DateTime.Parse(e.startDate.Split('|')[0]))
                .ToList();

            // Get the venues used in filtered events
            var venueIds = filteredEvents.Select(e => e.venueId).Distinct().ToHashSet();
            var filteredVenues = data.venues
                .Where(v => venueIds.Contains(v.id))
                .ToList();

            // Return filtered data
            var result = new EventData
            {
                events = filteredEvents,
                venues = filteredVenues
            };

            return Ok(result);   
        }
    }
}
