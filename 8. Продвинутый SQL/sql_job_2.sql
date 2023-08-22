---
SELECT COUNT (id)
FROM stackoverflow.posts
WHERE post_type_id=1 AND (score>300 or favorites_count >=100)
GROUP BY post_type_id

---
WITH count_qest AS (SELECT COUNT(id),
                creation_date::date
                FROM stackoverflow.posts
                WHERE post_type_id = 1 AND creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
                GROUP BY creation_date::date)

SELECT ROUND (AVG (count),0)
FROM count_qest

---
SELECT COUNT (DISTINCT sfu.id)
FROM stackoverflow.users AS sfu
JOIN stackoverflow.badges AS sfb ON sfu.id = sfb.user_id
WHERE sfu.creation_date::date = sfb.creation_date::date

---
SELECT COUNT (DISTINCT cp.id)
FROM (SELECT p.id
      FROM stackoverflow.posts AS p
      JOIN stackoverflow.users AS u ON p.user_id = u.id
      JOIN stackoverflow.votes AS v ON p.id = v.post_id
      WHERE u.display_name LIKE 'Joel Coehoorn'
      GROUP BY p.id
      HAVING COUNT (v.id) >=1) AS cp

---
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id

---
SELECT *
FROM (SELECT u.id,
            COUNT (v.user_id) AS cnt
            FROM stackoverflow.vote_types AS vt
            JOIN stackoverflow.votes AS v ON vt.id = v.vote_type_id
            JOIN stackoverflow.users AS u ON v.user_id = u.id
            WHERE name LIKE 'Close'
            GROUP BY u.id
            ORDER BY COUNT (v.user_id) DESC
            LIMIT 10) AS t
ORDER BY t.cnt DESC, t.id DESC

---
SELECT *,
       DENSE_RANK() OVER (ORDER BY t.cnt DESC) AS rank
FROM (SELECT COUNT (id) AS cnt,
             user_id       
       FROM stackoverflow.badges
       WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
       GROUP BY user_id
       ORDER BY cnt DESC, user_id
       LIMIT 10) AS t

---
SELECT title,
       user_id,
       score,
       ROUND (AVG(score) OVER (PARTITION BY user_id),0)
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score <> 0

---
SELECT title
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id
                  FROM stackoverflow.badges
                  GROUP BY user_id
                  HAVING COUNT (id) > 1000)
              AND title IS NOT NULL

---
SELECT id,
       views,
       CASE 
           WHEN views >= 350 THEN 1
           WHEN views >= 100 AND views < 350 THEN 2
           ELSE 3
       END AS group  
FROM stackoverflow.users
WHERE views > 0 AND location LIKE '%Canada%'

---
WiTH tab AS
(SELECT t.id,
       t.group,
       t.views,
       MAX(t.views) OVER (PARTITION BY t.group) AS max
FROM (SELECT id,
             views,
             CASE 
                WHEN views >= 350 THEN 1
                WHEN views >= 100 AND views < 350 THEN 2
                ELSE 3
             END AS group  
      FROM stackoverflow.users
      WHERE views > 0 AND location LIKE '%Canada%') AS t)
SELECT tab.id, 
       tab.views,  
       tab.group
FROM tab
WHERE tab.views = tab.max
ORDER BY tab.views DESC, tab.id


---
SELECT *,
       SUM(t.cnt_users) OVER (ORDER BY t.date_tr) AS sum_total
FROM (SELECT EXTRACT(DAY FROM creation_date::date) AS date_tr,
       COUNT(id) AS cnt_users
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY EXTRACT(DAY FROM creation_date::date)) AS t

---
WITH dt AS  (SELECT DISTINCT user_id,
                            MIN(creation_date) OVER (PARTITION BY user_id) AS min_dt
                            FROM stackoverflow.posts)

SELECT u.id,
       min_dt - creation_date
FROM stackoverflow.users AS u
JOIN dt ON u.id=dt.user_id

---
SELECT SUM (views_count), 
        DATE_TRUNC('month', creation_date)::date      
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-01-01' AND '2008-12-31'
GROUP BY DATE_TRUNC('month', creation_date)::date 
ORDER BY SUM (views_count) DESC

---
SELECT u.display_name,
       COUNT (DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users As u ON p.user_id = u.id
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month') AND post_type_id=2 
GROUP BY display_name
HAVING COUNT(p.user_id) > 100
ORDER BY u.display_name

---
SELECT COUNT (id),
       DATE_TRUNC('month', creation_date)::date
FROM stackoverflow.posts
WHERE user_id IN (SELECT u.id
                  FROM stackoverflow.users AS u
                  JOIN stackoverflow.posts AS p ON u.id = p.user_id
                  WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'
              AND DATE_TRUNC('month', p.creation_date)::date = '2008-12-01')
       AND DATE_TRUNC('year', creation_date)::date = '2008-01-01'
GROUP BY DATE_TRUNC('month', creation_date)::date
ORDER BY DATE_TRUNC('month', creation_date)::date DESC

---
SELECT user_id,
       creation_date,
       views_count,
       SUM (views_count) OVER (PARTITION BY user_id ORDER BY creation_date)       
FROM stackoverflow.posts

---
WITH t AS (SELECT user_id,
           COUNT (DISTINCT creation_date::date) AS c_day
           FROM stackoverflow.posts
           WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
           GROUP BY user_id)
SELECT ROUND (AVG (c_day), 0)
FROM t

---
WITH t AS (SELECT EXTRACT (MONTH FROM creation_date::date) AS month,
                  COUNT (id)
           FROM stackoverflow.posts
           WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
           GROUP BY EXTRACT (MONTH FROM creation_date::date))
SELECT *,
       ROUND(((count::numeric / LAG(count) OVER (ORDER BY month)) - 1) * 100,2)
FROM t

---
WITH t AS (SELECT user_id,
                  COUNT(DISTINCT id) AS cnt
           FROM stackoverflow.posts
           GROUP BY user_id
           ORDER BY cnt DESC
           LIMIT 1),

     t1 AS (SELECT p.user_id,
                   p.creation_date,
                   EXTRACT ('week' from p.creation_date) AS week_number
                   FROM stackoverflow.posts AS p
                   JOIN t ON t.user_id = p.user_id
                   WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01')
           

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number)
FROM t1
ORDER BY week_number;
