---
SELECT COUNT (status)
FROM company
WHERE status = 'closed'

---
SELECT funding_total
FROM company
WHERE country_code = 'USA' AND category_code = 'news'
ORDER BY funding_total DESC

---
SELECT SUM (price_amount)
FROM acquisition
WHERE term_code = 'cash' AND EXTRACT(YEAR from acquired_at) BETWEEN 2011 AND 2013

---
SELECT *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%'

---
SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

---
SELECT country_code,
       SUM (funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM (funding_total) DESC

---
SELECT funded_at,
       MIN (raised_amount),
       MAX (raised_amount)
FROM funding_round
GROUP BY funded_at 
HAVING MIN(raised_amount) NOT IN (0, MAX(raised_amount))

---
SELECT *,
        CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
           WHEN invested_companies< 20 THEN 'low_activity'
        END   
FROM fund

---
SELECT CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND (AVG (investment_rounds))
FROM fund
GROUP BY activity
ORDER BY ROUND (AVG (investment_rounds))

---
SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM (SELECT *
      FROM fund
      WHERE EXTRACT(YEAR FROM founded_at) BETWEEN 2010 AND 2012) AS f
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC
LIMIT 10;

---
SELECT p.first_name,
       p.last_name,
       e.instituition
       
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id

---
SELECT c.name,
    COUNT(DISTINCT(e.instituition))
FROM company c
INNER JOIN people p ON c.id = p.company_id
INNER JOIN education e ON p.id = e.person_id
GROUP BY name
ORDER BY COUNT(DISTINCT(e.instituition)) DESC
LIMIT 5

---
SELECT name
FROM company AS c
LEFT JOIN funding_round AS fr ON fr.company_id = c.id 
WHERE status = 'closed' AND (is_first_round=1 AND is_last_round=1)
GROUP BY name

---
SELECT p.id
FROM company AS c
INNER JOIN funding_round AS fr ON fr.company_id = c.id
INNER JOIN people AS p ON c.id = p.company_id
WHERE status = 'closed' AND (is_first_round=1 AND is_last_round=1)
GROUP BY p.id

---
SELECT DISTINCT p.id,
                e.instituition
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
LEFT JOIN education AS e ON p.id = e.person_id
WHERE c.status = 'closed'
   AND c.id IN (SELECT company_id
                FROM funding_round
                WHERE is_first_round = 1
                   AND is_last_round = 1)
   AND  e.instituition IS NOT NULL;

---
SELECT          p.id,
                COUNT (e.instituition)
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
LEFT JOIN education AS e ON p.id = e.person_id
WHERE c.status = 'closed'
   AND c.id IN (SELECT company_id
                FROM funding_round
                WHERE is_first_round = 1
                   AND is_last_round = 1)
   AND  e.instituition IS NOT NULL
GROUP BY p.id

---
SELECT AVG (tab1.count_in) 
FROM (SELECT DISTINCT p.id,
       COUNT (e.instituition) AS count_in
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
LEFT JOIN education AS e ON p.id = e.person_id
WHERE c.status = 'closed'
      AND c.id IN (SELECT company_id
                   FROM funding_round
                   WHERE is_first_round = 1
                   AND is_last_round = 1)
      AND  e.instituition IS NOT NULL
GROUP BY p.id) AS tab1

---
SELECT AVG (tab1.count_in) 
FROM (SELECT DISTINCT p.id,
       COUNT (e.instituition) AS count_in
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
LEFT JOIN education AS e ON p.id = e.person_id
WHERE e.instituition IS NOT NULL
      AND c.name = 'Facebook'
GROUP BY p.id) AS tab1

---
SELECT f.name AS funded_at,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
INNER JOIN company AS c ON c.id=i.company_id
INNER JOIN fund AS f ON f.id=i.fund_id
INNER JOIN funding_round AS fr ON fr.id=i.funding_round_id
WHERE c.milestones > 6 
      AND (EXTRACT(YEAR from fr.funded_at) BETWEEN 2012 AND 2013)

---
SELECT company.name AS acquiring_company,
       tab2.price_amount,
       tab2.acquired_company,
       tab2.funding_total,
       ROUND(tab2.price_amount / tab2.funding_total)
FROM
(
    SELECT c.name AS acquired_company,
           c.funding_total,
           tab1.acquiring_company_id,
           tab1.price_amount
    FROM company AS c
    RIGHT JOIN (
                SELECT acquiring_company_id,
                       acquired_company_id,
                       price_amount
                FROM acquisition
                WHERE price_amount > 0
               ) AS tab1 ON c.id = tab1.acquired_company_id
 ) AS tab2 LEFT JOIN company ON company.id  = tab2.acquiring_company_id
WHERE tab2.funding_total > 0
ORDER BY  tab2.price_amount DESC, tab2.acquired_company
LIMIT 10

---
SELECT name,
       EXTRACT(MONTH from fr.funded_at)
FROM company AS с
INNER JOIN funding_round AS fr ON с.id=fr.company_id
WHERE category_code = 'social' 
      AND (EXTRACT(YEAR from fr.funded_at) BETWEEN 2010 AND 2013)
      AND fr.raised_amount > 0

---
WITH 
tab1 AS (SELECT EXTRACT(MONTH from funded_at) AS month,
         COUNT (DISTINCT(f.name)) AS total_found
         FROM funding_round AS fr
         INNER JOIN investment AS i ON i.funding_round_id=fr.id
         INNER JOIN fund AS f ON f.id=i.fund_id
         WHERE (EXTRACT(YEAR from funded_at) BETWEEN 2010 AND 2013) 
                AND country_code = 'USA'
         GROUP BY EXTRACT(MONTH from funded_at)),
tab2 AS (SELECT EXTRACT(MONTH from acquired_at) AS month,
         COUNT (id) AS total_company,
         SUM (price_amount) AS total_sum
         FROM acquisition
         WHERE EXTRACT(YEAR from acquired_at) BETWEEN 2010 AND 2013 
         GROUP BY EXTRACT(MONTH from acquired_at))
 
 SELECT tab1.month,
        tab1.total_found,
        tab2.total_company,
        tab2.total_sum
FROM tab1 LEFT OUTER JOIN tab2 ON tab1.month=tab2.month

---
WITH
     inv_2011 AS (SELECT country_code,
                  AVG (funding_total) AS total_2011
                  FROM company
                  WHERE EXTRACT(YEAR from founded_at) = 2011
                  GROUP BY country_code),  -- сформируйте первую временную таблицу
     inv_2012 AS (SELECT country_code,
                  AVG (funding_total) AS total_2012
                  FROM company
                  WHERE EXTRACT(YEAR from founded_at) = 2012
                  GROUP BY country_code),   
     inv_2013 AS (SELECT country_code,
                  AVG (funding_total) AS total_2013
                  FROM company
                  WHERE EXTRACT(YEAR from founded_at) = 2013
                  GROUP BY country_code)
     
SELECT inv_2011.country_code,
       inv_2011.total_2011,
       inv_2012.total_2012,
       inv_2013.total_2013
       -- отобразите нужные поля
FROM inv_2011 -- укажите таблицу
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code-- присоедините таблицы
INNER JOIN inv_2013 ON inv_2011.country_code = inv_2013.country_code
ORDER BY inv_2011.total_2011 DESC
