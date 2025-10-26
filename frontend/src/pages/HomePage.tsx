import axios from "axios";
import { useEffect, useState } from "react";
import SlidingOverlay from "../components/SlidingOverlay";

const apiUrl = import.meta.env.VITE_API_URL;

type Event = {
  id: number;
  name: string;
  description?: string;
  day: number;
  startDate: string;
  venueId: number;
};

type Venue = {
  id: number;
  name: string;
  capacity: number;
  location: string;
};

type EventData = {
  events: Event[];
  venues: Venue[];
};

function HomePage() {
  // Raw data
  const [events, setEvents] = useState<Event[]>([]);
  const [venues, setVenues] = useState<Venue[]>([]);

  // Control
  const [isLoading, setIsLoading] = useState(false);
  const [open, setOpen] = useState(false);

  // Filter
  const [selectedVenue, setSelectedVenue] = useState<number | undefined>(
    undefined
  );
  const filteredEvents = events.filter(
    (event) => !selectedVenue || event.venueId === selectedVenue
  );

  const now = new Date();
  const [dateRange, setDateRange] = useState(`2022-10`);
  const [selectEvent, setSelectEvent] = useState<Event[]>([]);

  const modifyDateRange = (prev: string, monthChange = 0, yearChange = 0) => {
    let [currentYear, currentMonth] = prev.split("-").map(Number);

    // Apply month and year changes
    currentMonth += monthChange; // positive = add, negative = subtract
    currentYear += yearChange;

    // Adjust for month overflow/underflow
    while (currentMonth < 1) {
      currentMonth += 12;
      currentYear -= 1;
    }
    while (currentMonth > 12) {
      currentMonth -= 12;
      currentYear += 1;
    }

    setDateRange(`${currentYear}-${String(currentMonth).padStart(2, "0")}`);
  };

  const nowDateRange = () => {
    setDateRange(
      `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`
    );
  };

  const formatDateAndTime = (input: string): string[] => {
    return input.split("|");
  };

  useEffect(() => {
    const fetchBackend = async () => {
      setIsLoading(true);
      try {
        const res = await axios.get<EventData>(
          `${apiUrl}/event?month=${parseInt(
            dateRange.split("-")[1]
          )}&year=${parseInt(dateRange.split("-")[0])}`
        );
        if (res) {
          setEvents(res.data.events);
          setVenues(res.data.venues);
        }
      } catch (err) {
        console.log(err);
      } finally {
        setIsLoading(false);
      }
    };
    fetchBackend();
  }, [dateRange]);

  const Calendar = ({ year, month }: { year: number; month: number }) => {
    // Get first day of the month
    const firstDay = new Date(year, month - 1, 1).getDay(); // 0=Sun
    const daysInMonth = new Date(year, month, 0).getDate(); // days in current month
    const daysInPrevMonth = new Date(year, month - 1, 0).getDate(); // days in prev month

    // Build calendar grid
    const calendarDays: {
      day: number;
      currentMonth: boolean;
      events: Event[];
    }[] = [];

    // Previous month fill
    for (let i = firstDay - 1; i >= 0; i--) {
      calendarDays.push({
        day: daysInPrevMonth - i,
        currentMonth: false,
        events: filteredEvents.filter((e) => e.day == -i - 1),
      });
    }

    // Current month
    for (let i = 1; i <= daysInMonth; i++) {
      calendarDays.push({
        day: i,
        currentMonth: true,
        events: filteredEvents.filter((e) => e.day == i),
      });
    }

    // Next month fill to complete weeks
    let nextMonthDay = 1;
    while (calendarDays.length % 7 !== 0) {
      calendarDays.push({
        day: nextMonthDay,
        currentMonth: false,
        events: filteredEvents.filter(
          (e) => e.day == daysInMonth + nextMonthDay
        ),
      });
      nextMonthDay++;
    }

    return (
      <div className="mx-auto p-6 bg-white rounded-xl shadow-lg w-full">
        {/* Days of the Week */}
        <div className="grid grid-cols-7 text-center text-gray-500 font-semibold mb-3 uppercase tracking-wide">
          {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((d) => (
            <div key={d} className="py-1">
              {d}
            </div>
          ))}
        </div>

        {/* Dates */}
        <div className="grid grid-cols-7 gap-2 text-center">
          {calendarDays.map((d, idx) => (
            <div
              key={idx}
              className={`
                py-3 rounded-lg cursor-pointer transition-all
                ${
                  d.currentMonth
                    ? d.events.length > 0
                      ? "hover:bg-blue-300 text-gray-800 font-bold"
                      : "text-gray-800 font-bold"
                    : "text-gray-400"
                }
                ${
                  d.events.length > 0
                    ? d.currentMonth
                      ? "bg-blue-100"
                      : "bg-gray-100"
                    : "bg-none"
                }
              `}
              title={d.events.length > 0 ? `${d.events.length} event(s)` : ""}
              onClick={() => {
                if (d.events.length > 0) {
                  setSelectEvent(d.events);
                  setOpen(true);
                }
              }}
            >
              <span className="block text-sm">{d.day}</span>
              {d.events.length > 0 && (
                <span
                  className={`block mt-1 text-xs font-semibold ${
                    d.currentMonth ? "text-blue-600" : "text-gray-500"
                  }`}
                >
                  {d.events.length} {d.events.length === 1 ? "event" : "events"}
                </span>
              )}
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="flex flex-col items-center w-full gap-4">
      <div className="pt-4">
        <p className="font-bold">What's on at TEG Stadium !!!</p>
      </div>
      <div className="flex flex-col sm:flex-row items-center gap-4 sm:gap-6 md:gap-10">
        {/* Date Controls */}
        <div className="flex flex-row gap-2 border-r border-gray-300 p-2 rounded-lg bg-white shadow-sm items-center">
          <button
            onClick={() => modifyDateRange(dateRange, -1)}
            className="px-3 py-1 bg-gray-100 hover:bg-gray-200 rounded-md text-sm font-medium transition"
          >
            Prev
          </button>

          <input
            type="month"
            id="monthYear"
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
          />

          <button
            onClick={() => modifyDateRange(dateRange, 1)}
            className="px-3 py-1 bg-gray-100 hover:bg-gray-200 rounded-md text-sm font-medium transition"
          >
            Next
          </button>

          <button
            onClick={() => nowDateRange()}
            className="px-4 py-1 bg-blue-500 hover:bg-blue-600 text-white rounded-md text-sm font-medium transition"
          >
            Now
          </button>
        </div>

        {/* Venue Filter */}
        <div className="flex flex-row gap-2 items-center bg-white p-2 rounded-lg shadow-sm border border-gray-300">
          <label htmlFor="venueFilter" className="text-sm text-gray-600">
            Venue:
          </label>
          <select
            id="venueFilter"
            value={selectedVenue}
            onChange={(e) => {
              setSelectedVenue(
                e.target.value ? parseInt(e.target.value) : undefined
              );
            }}
            className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-400 bg-white"
          >
            <option value={undefined}>All Venues</option>
            {venues.map((venue) => (
              <option key={venue.id} value={venue.id}>
                {venue.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {!isLoading && (
        <Calendar
          year={parseInt(dateRange.split("-")[0])}
          month={parseInt(dateRange.split("-")[1])}
        />
      )}

      <SlidingOverlay
        isOpen={open}
        onClose={() => setOpen(false)}
        title={
          selectEvent.length > 0
            ? `Events on ${formatDateAndTime(selectEvent[0].startDate)[0]}`
            : ""
        }
        width="w-96"
      >
        {selectEvent.map((event) => {
          const venue = venues.find((v) => v.id === event.venueId);
          const [dateStr, timeStr] = formatDateAndTime(event.startDate);

          return (
            <div
              key={event.id}
              className="border rounded-lg p-4 my-4 shadow hover:shadow-lg transition"
            >
              <h2 className="text-lg font-semibold mb-1">{event.name}</h2>
              {event.description && (
                <p className="text-gray-600 mb-2">{event.description}</p>
              )}
              <p className="text-sm text-gray-500">
                <span className="font-medium">Date:</span> {dateStr}
              </p>
              <p className="text-sm text-gray-500">
                <span className="font-medium">Local Time:</span> {timeStr}
              </p>
              {venue && (
                <>
                  <p className="text-sm text-gray-500">
                    <span className="font-medium">Venue:</span> {venue.name}
                  </p>
                  <p className="text-sm text-gray-500">
                    <span className="font-medium">Location:</span>{" "}
                    {venue.location}
                  </p>
                </>
              )}
            </div>
          );
        })}
      </SlidingOverlay>
    </div>
  );
}

export default HomePage;
