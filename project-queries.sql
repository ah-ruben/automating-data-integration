--data used in report
CREATE TABLE movie_rental_sales AS
SELECT i.film_id, f.title, CASE l.language_id
WHEN 1 THEN 'Yes' ELSE 'No' END AS is_english, r.rental_id, r.customer_id,
p.payment_id, p.amount, p.payment_date
FROM rental r
LEFT JOIN payment p
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN language l
ON l.language_id=f.language_id
WHERE p.payment_id IS NOT NULL;
CREATE TABLE movie_sales_summary AS
SELECT title, SUM(amount) as sales, is_english
FROM movie_rental_sales
GROUP BY title, is_english
ORDER BY sales DESC;




--create tables for report sections
SELECT i.film_id, f.title, CASE l.language_id
WHEN 1 THEN 'Yes' ELSE 'No' END AS is_english, r.rental_id,
r.customer_id, p.payment_id, p.amount, p.payment_date
INTO movie_rental_sales
FROM rental r
LEFT JOIN payment p
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN language l
ON l.language_id=f.language_id
WHERE p.payment_id IS NOT NULL;
SELECT title, SUM(amount) as sales, is_english
INTO movie_rentals_summary
FROM movie_rental_sales
GROUP BY title, is_english
ORDER BY sales DESC;


--extracting raw data for detailed section
SELECT i.film_id, f.title, CASE l.language_id
WHEN 1 THEN 'Yes' ELSE 'No' END AS is_english, r.rental_id, r.customer_id,
p.payment_id, p.amount, p.payment_date
INTO movie_rental_sales
FROM rental r
LEFT JOIN payment p
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN language l
ON l.language_id=f.language_id
WHERE p.payment_id IS NOT NULL;



-- use to verify data accuracy
SELECT payment_id FROM movie_rental_sales
WHERE payment_id IS NOT NULL
EXCEPT
SELECT payment_id FROM payment
WHERE payment_id IS NOT NULL;

-- use to verify data accuracy
SELECT payment_id FROM movie_rental_sales
EXCEPT
SELECT payment_id FROM payment
WHERE payment_id IS NULL;


-- tranformation function
CREATE OR REPLACE FUNCTION is_movie_english(input_var INT)
RETURNS varchar(3)
LANGUAGE plpgsql
AS $$
DECLARE output_var varchar(3);
BEGIN
SELECT CASE WHEN input_var = 1 THEN 'Yes'
ELSE 'No'
END
INTO output_var;
RETURN output_var;
END;
$$;
-- Test with:
SELECT is_movie_english();


--trigger that cascades updates from detailed table to summary table
CREATE OR REPLACE FUNCTION alpha_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM movie_rentals_summary;
INSERT INTO movie_rentals_summary
SELECT title, SUM(amount) as sales, is_english
FROM movie_rental_sales
GROUP BY title, is_english
ORDER BY sales DESC;
RETURN NULL;
END;
$$;
CREATE TRIGGER new_rental_sale
AFTER INSERT
ON movie_rental_sales
FOR EACH STATEMENT
EXECUTE PROCEDURE alpha_trigger_function();
Test with: INSERT INTO movie_rental_sales (film_id, title, language_id,
rental_id, customer_id, payment_id, amount)
VALUES (9999, ‘Passing D191’, 99, 9999, 9999, 9999, 9.99)
DROP TRIGGER new_rental_sale ON movie_rental_sales CASCADE;



-- stored procedure to refresh data in both the detailed and summary tables
CREATE OR REPLACE PROCEDURE refresh
_tables()
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM movie_rental_sales;
DELETE FROM movie_rentals_summary;
INSERT INTO movie_rental_sales
SELECT i.film_id, f.title, CASE l.language_id
WHEN 1 THEN 'Yes' ELSE 'No' END AS is_english, r.rental_id, r.customer_id,
p.payment_id, p.amount, p.payment_date
FROM rental r
LEFT JOIN payment p
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN language l
ON l.language_id=f.language_id
WHERE p.payment_id IS NOT NULL;
INSERT INTO movie_rentals_summary
SELECT title, SUM(amount) as sales, is_english
FROM movie_rental_sales
GROUP BY title, is_english
ORDER BY sales DESC;
RETURN;
END;
$$;
--Test with:
SELECT COUNT(*) FROM movie_rental_sales;
DELETE FROM movie_rental_sales WHERE film_id BETWEEN 100 AND 400;
CALL refresh_tables();
