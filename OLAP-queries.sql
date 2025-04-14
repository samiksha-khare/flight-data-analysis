-- 1. Roll-Up (Aggregating Flight Delays by Year & Airline)

SELECT 
    d.Year, 
    a.Airline, 
    SUM(f.DepDelayMinutes) AS Total_Departure_Delay, 
    SUM(f.ArrDelayMinutes) AS Total_Arrival_Delay
FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
JOIN `bamboo-medium-450316-m8.flight_data.dim_airline` a 
    ON f.Airline_ID = a.Airline_ID
JOIN `bamboo-medium-450316-m8.flight_data.dim_date` d 
    ON f.Date_ID = d.Date_ID
GROUP BY d.Year, a.Airline
ORDER BY d.Year, Total_Departure_Delay DESC;


-- 2. Drill-Down: Taxi-In and Taxi-Out Times by Airport

SELECT 
    a.Airport_Name, 
    ROUND(AVG(f.TaxiIn), 2) AS Avg_TaxiIn, 
    ROUND(AVG(f.TaxiOut), 2) AS Avg_TaxiOut
FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
JOIN `bamboo-medium-450316-m8.flight_data.dim_airport` a 
    ON f.Origin_Airport_ID = CAST(a.Airport_ID AS STRING)  -- Convert Airport_ID to STRING
WHERE a.Airport_Name IS NOT NULL  -- Exclude missing airport names
GROUP BY a.Airport_Name
ORDER BY Avg_TaxiOut DESC;

-- 3. Dice: On-Time Performance for Flights Over a Certain Distance

SELECT 
    a.Airline, 
    f.Distance, 
    COUNT(f.Flight_ID) AS Total_Flights,
    SUM(CASE WHEN f.DepDel15 = 1 THEN 1 ELSE 0 END) AS Delayed_Flights
FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
JOIN `bamboo-medium-450316-m8.flight_data.dim_airline` a 
    ON CAST(f.Airline_ID AS INT64) = a.Airline_ID  -- Ensure data type match
WHERE f.Distance > 1000  -- Filtering for long-distance flights
GROUP BY a.Airline, f.Distance
ORDER BY f.Distance DESC;


-- 4. Pivot: Average Arrival Delay by Airline


SELECT * FROM (
  SELECT 
    a.Airline, 
    d.Year, 
    AVG(f.ArrDelayMinutes) AS Avg_Arrival_Delay
  FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
  JOIN `bamboo-medium-450316-m8.flight_data.dim_airline` a 
    ON CAST(f.Airline_ID AS INT64) = a.Airline_ID  -- Ensure data type match
  JOIN `bamboo-medium-450316-m8.flight_data.dim_date` d 
    ON f.Date_ID = d.Date_ID
  GROUP BY a.Airline, d.Year
)
PIVOT (
  AVG(Avg_Arrival_Delay) 
  FOR Year IN (2019, 2020, 2021)
);

-- 5. Total Flights by Airline, Month, and Airport (CUBE)

SELECT 
  a.Airline, 
  d.Month, 
  ap.Airport_Name, 
  COUNT(*) AS total_flights
FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
JOIN `bamboo-medium-450316-m8.flight_data.dim_airline` a 
    ON CAST(f.Airline_ID AS INT64) = a.Airline_ID  -- Ensure data type consistency
JOIN `bamboo-medium-450316-m8.flight_data.dim_date` d 
    ON f.Date_ID = d.Date_ID
JOIN `bamboo-medium-450316-m8.flight_data.dim_airport` ap 
    ON CAST(f.Origin_Airport_ID AS INT64) = CAST(ap.Airport_ID AS INT64)  -- Ensure data type consistency
GROUP BY a.Airline, d.Month, ap.Airport_Name
ORDER BY total_flights DESC;


-- 6. Cancellations by Airport and Year (Slice) <Extra>
SELECT 
    ap.Airport_Name AS Airport, 
    d.Year, 
    COUNT(*) AS Total_Cancellations
FROM `bamboo-medium-450316-m8.flight_data.fact_flight_data` f
JOIN `bamboo-medium-450316-m8.flight_data.dim_airport` ap 
    ON CAST(f.Origin_Airport_ID AS STRING) = CAST(ap.Airport_ID AS STRING)  -- Ensure data type consistency
JOIN `bamboo-medium-450316-m8.flight_data.dim_date` d 
    ON f.Date_ID = d.Date_ID
WHERE f.Cancelled = 1  
  AND d.Year = 2021  -- Filter for the year 2021
GROUP BY ap.Airport_Name, d.Year
ORDER BY Total_Cancellations DESC;


