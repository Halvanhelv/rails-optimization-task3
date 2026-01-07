# Task #3

In this task, you are asked to optimize a training `rails` application.

To run, you will need:
- `ruby 2.6.3`
- `postgres`

Running and usage:
- `bundle install`
- `bin/setup`
- `rails s`
- `open http://localhost:3000/buses/Samara/Moscow`

## Description of the Training Application
By visiting the page `buses/Samara/Moscow` you will see the bus schedule for this route.

## What to Optimize

### A. Data Import
When running `bin/setup`, trip data is loaded into the database from the file `fixtures/small.json`

The data loading from the file is done very naively (and inefficiently).

The task comes with files
- `example.json`
- `small.json` (1K trips)
- `medium.json` (10K trips)
- `large.json` (100K trips)

You need to optimize the schedule reloading mechanism from the file so that it imports the `large.json` file **within a minute**.

`rake reload_json[fixtures/large.json]`

To import this volume of data
- the gem https://github.com/zdennis/activerecord-import may help you
- avoid creating unnecessary transactions
- profile the import script with the tools you've learned and optimize it!

### B. Schedule Display
The schedule pages themselves are also generated inefficiently and start to slow down significantly as volumes grow.

You need to find and eliminate the problems that slow down the generation of these pages.

Try using
- [ ] `rack-mini-profiler`
- [ ] `rails panel`
- [ ] `bullet`
- [ ] query `explain`

### Submission
`PR` to this repository with code and case study similar to the first two weeks. This time there's no template, document your optimization process in free form.

In the case study indicate:
- how long it takes to import the `fixtures/large.json` file
- how long it takes to render the `buses/Samara/Moscow` page

Before submitting, make sure that the result of the `buses/Samara/Moscow` page for data from the `fixtures/example.json` file hasn't changed, meaning no functional changes were made, only optimizations.

It's better to protect against such regression with a test.

### bonus
*I advise starting the bonus only after completing the main part of the assignment.*

As a bonus, you need to handle importing files `1M.json` (`codename mega`) and `10M.json` (`codename hardcore`)

- [mega](https://www.dropbox.com/s/mhc2pzgtt4bp485/1M.json.gz?dl=1)
- [hardcore](https://www.dropbox.com/s/h08yke5phz0qzbx/10M.json.gz?dl=1)

## Hints

### Meta-information About the Data

When implementing the import, you need to consider our insider knowledge about the data:
- the primary key for a bus is `(model, number)`
- unique buses in the `10M.json` file ~ `10_000`
- unique cities in the `10M.json` file ~ `100`
- there are exactly `10` services, those listed in `Service::SERVICES`

### Streaming

The `10M.json` file weighs ~ `3Gb`.
So it's better not to try to load it entirely into memory and parse it.

Instead, it's better to read and parse it as a stream.

This is a more or less familiar scheme, but did you know that you can also import data into `Postgres` as a stream?

Here's a sketch of streaming reading from a file with streaming writing to `Postgres`:

```ruby
@cities = {}

ActiveRecord::Base.transaction do
  trips_command =
    "copy trips (from_id, to_id, start_time, duration_minutes, price_cents, bus_id) from stdin with csv delimiter ';'"

  ActiveRecord::Base.connection.raw_connection.copy_data trips_command do
    File.open(file_name) do |ff|
      nesting = 0
      str = +""

      while !ff.eof?
        ch = ff.read(1) # read one character at a time
        case
        when ch == '{' # object starts, nesting increases
          nesting += 1
          str << ch
        when ch == '}' # object ends, nesting decreases
          nesting -= 1
          str << ch
          if nesting == 0 # if trip-level object ended, parse and import it
            trip = Oj.load(str)
            import(trip)
            progress_bar.increment
            str = +""
          end
        when nesting >= 1
          str << ch
        end
      end
    end
  end
end

def import(trip)
  from_id = @cities[trip['from']]
  if !from_id
    from_id = cities.size + 1
    @cities[trip['from']] = from_id
  end

  # ...

  # stream prepared data chunk to postgres
  connection.put_copy_data("#{from_id};#{to_id};#{trip['start_time']};#{trip['duration_minutes']};#{trip['price_cents']};#{bus_id}\n")
end
```

### Plan

- clear the database
- iterate through the huge file
- along the way, form auxiliary dictionaries of limited size in memory (`cities`, `buses`, `buses_services`)
- immediately stream the main data to the database (`trips`) so as not to accumulate them
- after the file is finished, save the formed dictionaries to the database

### Notes

You can use any libraries for streaming `json` processing and in general
