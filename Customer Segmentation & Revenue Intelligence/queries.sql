USE chinook;

-- highest spending customers
SELECT * FROM Customer;
SELECT * FROM Invoice;
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country, 
ROUND(SUM(i.Total), 2) AS total_spending FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country ORDER BY total_spending DESC LIMIT 10;

-- most frequent purchases
SELECT * FROM Customer;
SELECT * FROM Invoice;
SELECT c.CustomerId,
CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
COUNT(i.InvoiceId) AS number_of_purchases FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName ORDER BY number_of_purchases DESC;

-- customers who have not purchased recently
SELECT * FROM Customer;
SELECT * FROM Invoice;
SELECT c.CustomerId,
CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
MAX(i.InvoiceDate) AS last_purchase_date FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName HAVING MAX(i.InvoiceDate) < (
SELECT DATE_SUB(MAX(InvoiceDate), INTERVAL 6 MONTH)
FROM Invoice ) ORDER BY last_purchase_date;

-- countries with highest value of customers
SELECT c.Country, ROUND(SUM(i.Total), 2) AS customer_value FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId GROUP BY c.Country ORDER BY customer_value DESC;

-- avg customer lifetime spending
SELECT ROUND(AVG(customer_spending), 2) AS average_lifetime_spending
FROM ( SELECT CustomerId, SUM(Total) AS customer_spending FROM Invoice GROUP BY CustomerId ) AS customer_totals;

-- most popular genres
SELECT * FROM Genre;
SELECT * FROM Track;
SELECT * FROM InvoiceLine;
SELECT g.Name AS genre, SUM(il.Quantity) AS tracks_purchased FROM Genre g
JOIN Track t ON g.GenreId = t.GenreId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY g.GenreId, g.Name ORDER BY tracks_purchased DESC;

-- artists with highest revenue 
SELECT ar.ArtistId, ar.Name AS artist, ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue FROM Artist ar
JOIN Album al ON ar.ArtistId = al.ArtistId
JOIN Track t ON al.AlbumId = t.AlbumId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY ar.ArtistId, ar.Name ORDER BY revenue DESC;

-- most frequently purchased track
SELECT t.TrackId, t.Name AS track, SUM(il.Quantity) AS times_purchased FROM Track t
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY t.TrackId, t.Name ORDER BY times_purchased DESC;

-- customer segments as high, medium,low values
WITH customer_spending AS ( SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country, SUM(i.Total) AS total_spending
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country )
SELECT CustomerId, customer_name, Country, ROUND(total_spending, 2) AS total_spending,
CASE
	WHEN total_spending >= 40 THEN 'High Value'
	WHEN total_spending >= 20 THEN 'Medium Value'
	ELSE 'Low Value'
END AS customer_segment
FROM customer_spending ORDER BY total_spending DESC LIMIT 50 OFFSET 10;

-- ranking customers by spending within each country
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country,
ROUND(SUM(i.Total), 2) AS total_spending,
RANK() OVER( PARTITION BY c.Country ORDER BY SUM(i.Total) DESC ) AS country_rank FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country ORDER BY c.Country, country_rank;

-- customer whose spending is above avg
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country,
ROUND(SUM(i.Total), 2) AS total_spending FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING SUM(i.Total) > ( SELECT AVG(customer_total) FROM ( 
SELECT SUM(Total) AS customer_total FROM Invoice GROUP BY CustomerId ) AS spending
) ORDER BY total_spending;

-- top 3 customers in each country
WITH customer_spending AS ( SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
c.Country, SUM(i.Total) AS total_spending FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
),
ranked AS ( SELECT CustomerId, customer_name, Country, total_spending,
RANK() OVER (PARTITION BY Country ORDER BY total_spending DESC ) AS country_rank FROM customer_spending
)
SELECT CustomerId, customer_name, Country, ROUND(total_spending, 2) AS total_spending, country_rank
FROM ranked WHERE country_rank <= 3 ORDER BY Country, country_rank;

-- customer who purchase from multiple genres
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
COUNT(DISTINCT g.GenreId) AS genres_purchased FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
JOIN Track t ON il.TrackId = t.TrackId
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY c.CustomerId, c.FirstName, c.LastName HAVING COUNT(DISTINCT g.GenreId) > 1 ORDER BY genres_purchased DESC;

-- customers % cont. to total revenue
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, 
ROUND(SUM(i.Total), 2) AS total_spending,
ROUND( 100 * SUM(i.Total) / SUM(SUM(i.Total)) OVER (), 2 ) AS revenue_percentage FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName ORDER BY revenue_percentage DESC;

-- cumulative revenue
WITH customer_spending AS
( SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) 
AS customer_name, SUM(i.Total) AS total_spending FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId GROUP BY c.CustomerId, c.FirstName, c.LastName )

SELECT CustomerId, customer_name,
ROUND(total_spending, 2) AS total_spending,
ROUND( SUM(total_spending) OVER ( ORDER BY total_spending DESC ROWS UNBOUNDED PRECEDING ), 2 )
AS cumulative_revenue FROM customer_spending ORDER BY total_spending DESC;

-- month with hightest revenue
SELECT YEAR(InvoiceDate) AS sales_year, MONTH(InvoiceDate) AS sales_month, DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
ROUND(SUM(Total), 2) AS revenue FROM Invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate),
DATE_FORMAT(InvoiceDate, '%Y-%m') ORDER BY revenue DESC;