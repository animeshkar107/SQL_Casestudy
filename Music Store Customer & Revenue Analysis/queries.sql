-- showing and using db
SHOW DATABASES;
USE chinook;

-- showing tables
SHOW TABLES;

-- total revenue
SELECT * FROM Invoice;
SELECT ROUND(SUM(Total), 2) AS total_revenue FROM Invoice;

-- highest revenue countries
SELECT BillingCountry AS country, ROUND(SUM(Total), 2) AS revenue FROM Invoice
GROUP BY BillingCountry ORDER BY revenue DESC;

-- top 10 customer by spending
SELECT * FROM invoice;
SELECT * FROM Customer;
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country,
ROUND(SUM(i.Total), 2) AS total_spending, RANK() OVER (ORDER BY SUM(i.Total) DESC) AS spending_rank
FROM Customer c 
JOIN Invoice i ON c.CustomerId = i.CustomerId GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
ORDER BY spending_rank LIMIT 10;

-- highest revenue artist
SELECT * FROM Artist;
SELECT * FROM Album;
SELECT * FROM Track;
SELECT * FROM InvoiceLine;
SELECT ar.ArtistId, ar.Name AS artist, ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM Artist ar JOIN Album al ON ar.ArtistId = al.ArtistId
JOIN Track t ON al.AlbumId = t.AlbumId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY ar.ArtistId, ar.Name ORDER BY revenue DESC;

-- most popular genres
SELECT * FROM Genre;
SELECT g.Name AS genre, SUM(il.Quantity) AS tracks_purchased
FROM Genre g JOIN Track t ON g.GenreId = t.GenreId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY g.GenreId, g.Name
ORDER BY tracks_purchased DESC;

-- highest sales album
SELECT al.AlbumId, al.Title AS album, ar.Name AS artist,
ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS sales FROM Album al
JOIN Artist ar ON al.ArtistId = ar.ArtistId
JOIN Track t ON al.AlbumId = t.AlbumId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY al.AlbumId, al.Title, ar.Name ORDER BY sales DESC;

-- most frequently purchased tracks
SELECT * FROM Album;
SELECT * FROM Artist;
SELECT * FROM Track;
SELECT * FROM InvoiceLine;
SELECT t.TrackId, t.Name AS track, ar.Name AS artist,
SUM(il.Quantity) AS times_purchased FROM Track t
JOIN InvoiceLine il ON t.TrackId = il.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY t.TrackId, t.Name, ar.Name ORDER BY times_purchased DESC LIMIT 20;

-- avg spending
SELECT ROUND(AVG(customer_spending), 2) AS average_customer_spending
FROM ( SELECT CustomerId, SUM(Total) AS customer_spending 
FROM Invoice GROUP BY CustomerId ) AS customer_totals;

-- never purchased
SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, c.Country, c.Email FROM Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId WHERE i.InvoiceId IS NULL ORDER BY c.CustomerId;

-- employees support highest value customers
SELECT * FROM Employee;
WITH customer_value AS ( SELECT c.CustomerId, c.SupportRepId,
CONCAT(c.FirstName, ' ', c.LastName) AS customer_name, 
SUM(i.Total) AS customer_spending FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId 
GROUP BY c.CustomerId, c.SupportRepId, c.FirstName, c.LastName )
SELECT e.EmployeeId, CONCAT(e.FirstName, ' ', e.LastName) AS employee_name,
COUNT(cv.CustomerId) AS customers_supported, ROUND(SUM(cv.customer_spending), 2) AS total_customer_revenue,
ROUND(AVG(cv.customer_spending), 2) AS average_customer_value FROM Employee e
JOIN customer_value cv ON e.EmployeeId = cv.SupportRepId
GROUP BY e.EmployeeId, e.FirstName, e.LastName ORDER BY total_customer_revenue DESC;

-- revenue from each country
SELECT BillingCountry AS country, ROUND(SUM(Total), 2) AS revenue,
ROUND( 100 * SUM(Total) / SUM(SUM(Total)) OVER (), 2 ) AS revenue_percentage
FROM Invoice GROUP BY BillingCountry ORDER BY revenue DESC;

-- genres highest revenue 
SELECT g.Name AS genre, ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM Genre g JOIN Track t ON g.GenreId = t.GenreId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY g.GenreId, g.Name ORDER BY revenue DESC;

-- yearly revenue trend
SELECT YEAR(InvoiceDate) AS sales_year, ROUND(SUM(Total), 2) AS revenue
FROM Invoice GROUP BY YEAR(InvoiceDate) ORDER BY sales_year;

-- artist having largest tracks
SELECT ar.ArtistId, ar.Name AS artist, COUNT(t.TrackId) AS number_of_tracks FROM Artist ar
JOIN Album al ON ar.ArtistId = al.ArtistId
JOIN Track t ON al.AlbumId = t.AlbumId
GROUP BY ar.ArtistId, ar.Name ORDER BY number_of_tracks DESC LIMIT 20;

-- customers spending above avg
SELECT * FROM invoice;
SELECT * FROM Customer;

SELECT c.CustomerId, CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
ROUND(SUM(i.Total), 2) AS total_spending,
CASE
	WHEN SUM(i.Total) >= 40 THEN 'High Value'
	WHEN SUM(i.Total) >= 20 THEN 'Medium Value'
	ELSE 'Low Value'
END AS customer_segment
FROM Customer c JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName ORDER BY total_spending DESC;