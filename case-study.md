# Optimization Case Study

## Establishing the Metric
To understand whether my changes have a positive effect on program performance, I decided to use this metric:
First, I decided to parse the small.json file
I wrapped the rake task in Benchmark.measure - as a result, the processing (parsing) time of the small.json file was 10 seconds

Here's how I built the `feedback_loop`:

- Profiling
- Finding growth points (PGHERO)
- Optimization
- Running tests to make sure the program returns the correct result (works correctly)
- Metric (using Benchmark.measure to determine execution time)

To protect against regression, I wrote a test checking the number of saved records in the database for each table

### Finding #1
I used PGHERO and it showed me the following picture (after running the medium.json import script)
![pghero_mediun first](https://i.imgur.com/dJrZE3q.png)
I followed PGHERO's recommendation and added an index for the number field in the buses table
import speed decreased from 10 to 9.6 seconds

### Finding #2
I removed unnecessary intermediate variables and started writing the object directly to the array
import speed decreased from 9.6 to 8.7 seconds

### Finding #3
I replaced find_or_create_by with find_or_initialize_by for Bus
import speed decreased from 8.7 to 7.9 seconds


### Finding #4
PGHERO showed that the script is hitting the intermediate table
I created a model for the intermediate table and started writing data directly there, bypassing the association
import speed decreased from 7.9 to 6 seconds

### Finding #5
PGHERO showed that the bus table is called twice
I combined object creation and its update
import speed decreased from 6 to 4.6 seconds

### Finding #6
Removed unnecessary find_or_create_by call for Bus
import speed decreased from 4.6 to 4.4 seconds

### Finding #7
Removed unnecessary find_or_create_by call for Service
import speed decreased from 4.4 to 3.1 seconds

### Finding #8
Changed file to fixtures/medium
Added records for Trip in import
import speed decreased from 21 to 14 seconds

### Finding #9
Added records for City in import
import speed decreased from 14 to 6.6 seconds

### Finding #10
Changed file to fixtures/large
import speed decreased from ~infinity to 36 seconds

### Page Load Acceleration

### Finding #1
Using the bullet gem, I saw that there was an n+1 problem
removed the problem, loading speed improved noticeably

### Finding #1
Made a couple of mini fixes in views
loading speed improved slightly

### Finding #2
Added all necessary indexes
Speed increased significantly

### Finding #3
rack-mini-profiler gem showed that view fragments are loading in huge quantities
I added caching for such fragments, page loading speed decreased significantly

### Additional notes:
Additionally made sure that cache is cleared on each data import, this is the ideal option for the application
Didn't move all fragments to one view since caching solved the page loading problem, now the page loads in ~ 200ms

Wrote a test to verify the generated html
