-- load database and create databasecustomer
create database air_cargo_db;
use air_cargo_db;

/* Task 1 -- Create an ER diagram for the given airline's database */

SELECT 
    *
FROM
    customer;
SELECT 
    *
FROM
    passengers_on_flights;
SELECT 
    *
FROM
    routes;
SELECT 
    *
FROM
    ticket_details;

describe customer ;
describe passengers_on_flights;
describe routes;
describe ticket_details;

-- Assign primary key and foreign key 

alter table customer 
add primary key (customer_id);

alter table routes add primary key (route_id);

alter table passengers_on_flights 
add primary key (route_id, customer_id),
add foreign key (customer_id) references customer(customer_id),
add foreign key (route_id) references routes(route_id);

alter table ticket_details 
add foreign key (customer_id) references customer(customer_id),
add foreign key (customer_id) references passengers_on_flights (customer_id);

/* Task 2 --  Write a query to create a route_details table using suitable data types for the fields,
such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles;
implement the check constraint for the flight number and unique constraint for the route_id fields;
also, make sure that the distance miles field is greater than 0 
*/

CREATE TABLE route_details (
    route_id INT UNIQUE,
    flight_num INT,
    origin_airport VARCHAR(15),
    destination_airport VARCHAR(15),
    aircraft_id VARCHAR(10),
    distance_miles INT,
    CHECK (flight_num IS NOT NULL),
    CHECK (distance_miles > 0)
);

describe route_details;

/* Task 3 --  Write a query to display all the passengers (customers) who have 
traveled on routes 01 to 25; refer to the data from the 
passengers_on_flights table 
*/

SELECT 
    *
FROM
    passengers_on_flights
WHERE
    route_id BETWEEN 01 AND 25
ORDER BY customer_id;

/* Task 4 -- Write a query to identify the number of passengers and total revenue in 
business class from the ticket_details table.
*/

SELECT 
    COUNT(DISTINCT customer_id) AS Total_Passengers,
    SUM(no_of_tickets * Price_per_ticket) AS Total_Revenue
FROM
    ticket_details
WHERE
    class_id = 'Bussiness';



/* Task 5 -- Write a query to display the full name of the customer by extracting the 
first name and last name from the customer table.
*/

SELECT 
    customer_id,
    CONCAT(TRIM(first_name), ' ', TRIM(last_name)) AS Name_of_Customer
FROM
    customer;

/* Task 6 -- Write a query to extract the customers who have registered and 
booked a ticket. Use data from the customer and ticket_details tables.
*/

SELECT 
    *
FROM
    customer c
        RIGHT JOIN
    ticket_details t ON c.customer_id = t.customer_id;

/* Task 7 -- Write a query to identify the customer’s first name and last name based 
on their customer ID and brand (Emirates) from the ticket_details table
*/

SELECT 
    t.customer_id, c.first_name, c.last_name, t.brand
FROM
    ticket_details t
        LEFT JOIN
    customer c ON t.customer_id = c.customer_id
WHERE
    t.brand = 'Emirates';

/* Task 8 -- Write a query to identify the customers who have traveled by Economy 
Plus class using Group By and Having clause on the 
passengers_on_flights table.
*/

SELECT
    c.customer_id, c.first_name, c.last_name, p.class_id
FROM
    passengers_on_flights p
        JOIN
    customer c ON p.customer_id = c.customer_id
GROUP BY 1 , 2 , 3 , 4
HAVING p.class_id = 'Economy Plus'
ORDER BY 1;

/* Task 9 --  Write a query to identify whether the revenue has crossed 10000 using 
the IF clause on the ticket_details table
*/

SELECT 
    SUM(no_of_tickets * Price_per_ticket) AS Total_revenue,
    IF('Total_revenue' < 10000,
        'Crossed 10000',
        'Not-Crossed 10000') AS Revenue_Status
FROM
    ticket_details;

/* Task 10 --  Write a query to create and grant access to a new user to perform 
operations on a database.
*/

-- create new user
create user 'new_user'@'localhost' identified by 'User@123';

-- grant access to the database air_cargo_db
grant all privileges on air_cargo_db.* to 'new_user'@'localhost';

-- apply changes
flush privileges;

-- limited access (only select )
grant select on air_cargo_db.* to 'new_user'@'localhost';

-- limited access ( only select and insert)
grant select, insert on air_cargo_db.* to 'new_user'@'localhost';

/* Task 11 - Write a query to find the maximum ticket price for each class using 
window functions on the ticket_details table.
*/

with cte as (
select class_id, max(price_per_ticket) as Maximum_price, 
dense_rank () over (partition by class_id) as dense
from ticket_details
group by class_id order by Maximum_price desc)
select class_id, Maximum_price from cte where dense = 1;

/* Task 12 -- Write a query to extract the passengers whose route ID is 4 by 
improving the speed and performance of the passengers_on_flights 
table.
*/

SELECT 
    *
FROM
    passengers_on_flights
WHERE
    route_id = 4; -- took 0.55 sec to execute

-- using index 
create index idx_route_id on passengers_on_flights(route_id);
-- checking index
show indexes from passengers_on_flights;
-- Fetching details using index -- 
SELECT 
    *
FROM
    routes
WHERE
    route_id = 4;
-- now execution time limited to ~ 0

/* Task 13 --  For route ID 4, write a query to view the execution plan of the 
passengers_on_flights table
*/

SELECT 
    customer_id,
    route_id,
    aircraft_id,
    depart,
    arrival,
    flight_num
FROM
    passengers_on_flights
WHERE
    route_id = 4;

/* Task 14 -- Write a query to calculate the total price of all tickets booked by a 
customer across different aircraft IDs using the rollup function.
*/

SELECT 
    customer_id,
    aircraft_id,
    SUM(no_of_tickets * price_per_ticket) AS total_ticket_price
FROM
    ticket_details
GROUP BY customer_id , aircraft_id WITH ROLLUP;
 
/* Task 15 -- Write a query to create a view with only business class customers along 
with the brand of airlines.
*/

CREATE VIEW bussiness_class AS
    SELECT 
        c.first_name, c.last_name, t.brand
    FROM
        customer c
            JOIN
        ticket_details t USING (customer_id)
    WHERE
        class_id IN ('Bussiness');

SELECT 
    *
FROM
    business_class;

/* Task 16 --  Write a query to create a stored procedure to get the details of all 
passengers flying between a range of routes defined in run time. Also, 
return an error message if the table doesn't exist
*/

DELIMITER $$

CREATE PROCEDURE GetPassengersByRouteRange(IN startRoute INT, IN endRoute INT)
BEGIN
    DECLARE table_exists INT DEFAULT 0;

    -- Check if the table exists
    SELECT COUNT(*) INTO table_exists
    FROM information_schema.tables
    WHERE table_schema = 'air_cargo_db' 
      AND table_name = 'passengers_on_flights';

    -- If table exists, run the query
    IF table_exists = 1 THEN
        SELECT * 
        FROM passengers_on_flights
        WHERE route_id BETWEEN startRoute AND endRoute;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Table passengers_on_flights does not exist.';
    END IF;
END$$

DELIMITER ;

CALL GetPassengersByRouteRange(100, 200);

/* Task 17 -- Write a query to create a stored procedure that extracts all the details 
from the routes table where the traveled distance is more than 2000 
miles.
*/

drop procedure if exists distance;
delimiter //
create procedure distance ( in miles int)
begin
select * from routes
where distance_miles >miles
order by distance_miles;
end//
delimiter ;

call distance (2000);

/* Task 18 -- Write a query to create a stored procedure that groups the distance 
traveled by each flight into three categories. The categories are, short 
distance travel (SDT) for >=0 AND <= 2000 miles, intermediate distance 
travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for 
>6500.
*/

DELIMITER $$

CREATE PROCEDURE CategorizeFlightDistances()
BEGIN
    SELECT 
        flight_num,
        distance_miles,
        CASE
            WHEN distance_miles >= 0 AND distance_miles <= 2000 THEN 'Short Distance Travel (SDT)'
            WHEN distance_miles > 2000 AND distance_miles <= 6500 THEN 'Intermediate Distance Travel (IDT)'
            WHEN distance_miles > 6500 THEN 'Long Distance Travel (LDT)'
            ELSE 'Unknown Category'
        END AS Distance_Category
    FROM routes;
END$$

DELIMITER ;

CALL CategorizeFlightDistances();

/* Task 19 -- Write a query to extract ticket purchase date, customer ID, and class ID 
and specify if the complimentary services are provided for the specific 
class using a stored function in the stored procedure on the 
ticket_details table.
 Condition:
 • If the class is Business and Economy Plus, then complimentary services 
are given as Yes, else it is No
*/

DELIMITER $$

CREATE FUNCTION GetComplimentaryService(class VARCHAR(50))
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(3);

    IF class IN ('Bussiness', 'Economy Plus') THEN
        SET result = 'Yes';
    ELSE
        SET result = 'No';
    END IF;

    RETURN result;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE GetTicketDetailsWithComplimentary()
BEGIN
    SELECT 
        p_date AS Ticket_Purchase_Date,
        customer_id,
        class_id,
        GetComplimentaryService(class_id) AS Complimentary_Service
    FROM ticket_details;
END$$

DELIMITER ;

CALL GetTicketDetailsWithComplimentary();

/* Task 20 -- Write a query to extract the first record of the customer whose last 
name ends with Scott using a cursor from the customer table. */

DELIMITER $$

CREATE PROCEDURE GetFirstCustomerWithLastNameScott()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_first_name VARCHAR(100);
    DECLARE v_last_name VARCHAR(100);
    DECLARE v_date_of_birth DATE;
    DECLARE v_gender VARCHAR(10);

    -- Cursor to select customers with last name ending in 'Scott'
    DECLARE cur CURSOR FOR
        SELECT customer_id, first_name, last_name, date_of_birth, gender
        FROM customer
        WHERE last_name LIKE '%Scott';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    FETCH cur INTO v_customer_id, v_first_name, v_last_name, v_date_of_birth, v_gender;

    IF NOT done THEN
        SELECT 
            v_customer_id AS Customer_ID,
            v_first_name AS First_Name,
            v_last_name AS Last_Name,
            v_date_of_birth AS DOB,
            v_gender AS Gender;
    END IF;

    CLOSE cur;
END$$

DELIMITER ;

CALL GetFirstCustomerWithLastNameScott();

-- Total revenue generating routes
SELECT 
    r.route_id,
    r.origin_airport,
    r.destination_airport,
    SUM(t.no_of_tickets * t.price_per_ticket) AS total_revenue
FROM routes r
JOIN passengers_on_flights p ON r.route_id = p.route_id
JOIN ticket_details t ON p.customer_id = t.customer_id
GROUP BY r.route_id, r.origin_airport, r.destination_airport
ORDER BY total_revenue DESC
LIMIT 5;

-- repeate customer - frequent flyers
SELECT 
    customer_id,
    COUNT(DISTINCT route_id) AS routes_travelled
FROM passengers_on_flights
GROUP BY customer_id
HAVING COUNT(DISTINCT route_id) > 2;

-- class wise revenue contribution
SELECT 
    class_id,
    SUM(no_of_tickets * price_per_ticket) AS revenue,
    ROUND(
        100 * SUM(no_of_tickets * price_per_ticket) /
        SUM(SUM(no_of_tickets * price_per_ticket)) OVER (),
        2
    ) AS revenue_percentage
FROM ticket_details
GROUP BY class_id;

-- peak travel routes (high passanger count)
SELECT 
    route_id,
    COUNT(customer_id) AS passenger_count
FROM passengers_on_flights
GROUP BY route_id
ORDER BY passenger_count DESC
LIMIT 5;

-- Customers Who Never Booked Tickets
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
LEFT JOIN ticket_details t 
ON c.customer_id = t.customer_id
WHERE t.customer_id IS NULL;

-- revenue trend by purchase date
SELECT 
    p_date,
    SUM(no_of_tickets * price_per_ticket) AS daily_revenue
FROM ticket_details
GROUP BY p_date
ORDER BY p_date;

-- Rank Flights by Distance (Window Function)\
SELECT 
    flight_num,
    distance_miles,
    RANK() OVER (ORDER BY distance_miles DESC) AS distance_rank
FROM routes;

-- Business vs Economy Passenger Ratio
SELECT 
    class_id,
    COUNT(*) AS passenger_count
FROM passengers_on_flights
GROUP BY class_id;
