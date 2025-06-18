--Question 1
--17.5% for top 10% of firms by modified ROA.

DROP VIEW IF EXISTS q1;
CREATE VIEW q1 AS
SELECT 
	gvkey,
	fyear,
	conm,
	q_tot,
	ni/(at + K_int_offBS) AS mod_roa,
	NTILE(10) OVER(ORDER BY ni/(at + K_int_offBS) DESC) AS roa_decile,
	NTILE(10) OVER(ORDER BY q_tot DESC) AS q_decile
FROM Fundamentals_Annual
LEFT JOIN Total_q
USING (gvkey, fyear)
WHERE loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND fyear = 2021
	AND at >= 1000
	AND emp IS NOT NULL
	AND sale IS NOT NULL
	AND ni IS NOT NULL
	AND q_tot IS NOT NULL;

SELECT
	AVG(mod_roa)
FROM q1
WHERE roa_decile = 1;
	
--Question 2
--It is -13.4%
SELECT
	AVG(mod_roa)
FROM q1
WHERE roa_decile = 10;


--Question 3
--2.4%
SELECT
	AVG(mod_roa)
FROM q1
WHERE q_decile = 1;


--Question 4
--Average q_decile for firms in top decile of ROA
--3.8
SELECT
	AVG(q_decile)
FROM q1
WHERE roa_decile = 1;


--Question 5
--Average q_decile for firms in bottom decile of ROA
--4.4
SELECT
	AVG(q_decile)
FROM q1
WHERE roa_decile = 10;

--Question 6
--Creating the cohorts in 2012
DROP VIEW IF EXISTS q6;
CREATE VIEW q6 AS
SELECT 
	gvkey,
	NTILE(10) OVER(ORDER BY q_tot DESC) AS q_decile_2012
FROM Fundamentals_Annual
LEFT JOIN Total_q
USING (gvkey, fyear)
WHERE loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND fyear = 2012
	AND at >= 1000
	AND emp IS NOT NULL
	AND sale IS NOT NULL
	AND ni IS NOT NULL
	AND q_tot IS NOT NULL;

--How did this group do in 2021?
--These are the 845 firms in 2021 that were in the cohorts from before
DROP VIEW IF EXISTS q6_part2;
CREATE VIEW q6_part2 AS
SELECT
	gvkey,
	fyear,
	conm,
	ni/(at + K_int_offBS) AS mod_roa
FROM Fundamentals_Annual
LEFT JOIN Total_q
USING (gvkey, fyear)
WHERE fyear = 2021 
	AND gvkey IN 
			(SELECT gvkey
			 FROM q6);

			 
--It was decile 3, 1, and then 2 placing in the top three spots.
--Note that some students interpreted the question to also screen the 2021 data
--As they did in 2012, and got a different answer.
--I have also graded those as correct.
SELECT
	q_decile_2012,
	AVG(mod_roa) AS mod_roa_avg
FROM q6_part2
LEFT JOIN q6
USING (gvkey)
GROUP BY q_decile_2012
ORDER BY mod_roa_avg DESC;

--Question 1

DROP VIEW IF EXISTS q1;
CREATE VIEW q1 AS
SELECT
	gvkey,
	fyear,
	conm,
	at,
	ni,
	emp,
	naicsh,
	EXEC_FULLNAME,
	CEOANN,
	TDC1,
	K_int_offBS,
	q_tot
FROM Fundamentals_Annual
LEFT JOIN Execucomp
USING (gvkey, fyear)
LEFT JOIN Total_q
USING (gvkey,fyear)
WHERE
	at >= 1000
	AND ni IS NOT NULL
	AND emp IS NOT NULL
	AND fyear = 2021
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND TDC1 IS NOT NULL
	AND CEOANN = 'CEO'
	AND q_tot IS NOT NULL
	AND K_int_offBS IS NOT NULL;

	
--Question 2
--5.13%
SELECT
	AVG(ni/(at + K_int_offBS)) AS roa_avg
FROM q1;


--Question 3, part 1
DROP VIEW IF EXISTS q3;
CREATE VIEW q3 AS 
SELECT
	gvkey,
	fyear,
	conm,
	TDC1,
	EXEC_FULLNAME,
	ni,
	at,
	K_int_offBS,
	q_tot,
	naicsh,
	NTILE(4) OVER(PARTITION BY fyear ORDER BY TDC1 DESC) AS pay_quartile
FROM q1;

--Question 3, part 2 - ROA by quartile
--Ranges from 6.2% to 4.0%
--Note: Are there other confounding effects here to pay attention to?
SELECT
	pay_quartile,
	AVG(ni/(at + K_int_offBS)) AS roa_avg
FROM q3
GROUP BY pay_quartile;


--Question 4
SELECT
	AVG(q_tot) AS q_avg
FROM q1;


--Question 5
--Why does q_tot_avg get higher as you go lower?
--What else to control for?
SELECT
	pay_quartile,
	AVG(q_tot) AS q_tot_avg
FROM q3
GROUP BY pay_quartile;


--Although not asked in the question, note how asset size is smaller for the 
--lowest quartile of pay, which is not surprising.
--Worth further investigation for another day.
SELECT
	pay_quartile,
	AVG(q_tot) AS q_tot_avg,
	AVG(at) AS at_avg
FROM q3
GROUP BY pay_quartile;	


--Question 1
--First set of screens
--Getting the 2021 screens in order
DROP VIEW IF EXISTS q1_part1;
CREATE VIEW q1_part1 AS
SELECT
	gvkey,
	fyear,
	conm,
	ni,
	at,
	emp,
	q_tot,
	K_int_offBS,
	naicsh,
	COUNT(gvkey) OVER(PARTITION by fyear, naicsh) AS ind_size
FROM Fundamentals_Annual
LEFT JOIN Total_q
USING (gvkey, fyear)
WHERE
	fyear = 2021
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND at >= 1000
	AND ni IS NOT NULL
	AND emp IS NOT NULL
	AND q_tot IS NOT NULL
	AND K_int_offBS IS NOT NULL
	AND naicsh >= 100000;

--This leaves us with 1035 firms in 2021 with at least three firms in industry
--Here are the relevant fsps.
--Note that fsp should ideally be calculated on the 2021 sample,
--before we do the "at least 10 years screen"
DROP VIEW IF EXISTS q1_part2;
CREATE VIEW q1_part2 AS
SELECT *,
	ni/(at + K_int_offBS) - AVG(ni/(at + K_int_offBS)) OVER(PARTITION BY fyear, naicsh) AS fsp
FROM q1_part1
WHERE ind_size >= 3;


--Table of distinct gvkeys from 2011 and earlier
--This is a set of 26,107 gvkeys
DROP VIEW IF EXISTS q1_gvkey_early;
CREATE VIEW q1_gvkey_early AS
SELECT 
	DISTINCT gvkey
FROM Fundamentals_Annual
WHERE gvkey in
	(SELECT gvkey
     FROM Fundamentals_Annual
	 WHERE fyear <= 2011);

	 
--The finale
--Using the fsp data, and then winnowing down the firms with early gvkeys
--Leaves us with 724 firms.
DROP VIEW IF EXISTS q1_finalsample;
CREATE VIEW q1_finalsample AS
SELECT *
FROM q1_part2
INNER JOIN q1_gvkey_early
USING (gvkey);


--Question 2
--Note that given the ambiguity in the question,
--I will accept answers either using 2017 or 2016 as the start year.
--My answer is using 2017 as the start year.
--These are all firms in Execucomp with 5 or fewer years, were not in 2016 or earlier.
--I get 277 such firms
DROP VIEW IF EXISTS CEO_5yrs;
CREATE VIEW CEO_5yrs AS
SELECT 
	DISTINCT gvkey
FROM Execucomp
WHERE fyear BETWEEN 2017 AND 2021
	AND CEOANN = 'CEO'
	AND CO_PER_ROL NOT IN
	(SELECT CO_PER_ROL
	 FROM Execucomp
	 WHERE fyear <= 2016
		AND CEOANN = 'CEO');

--Then, merge this with q1.
SELECT *
FROM q1_finalsample
INNER JOIN CEO_5yrs
USING (gvkey);


--Q3
--More than 5 years
--Since 2016 or earlier.
--Here are all the gvkey plus CO_PER_ROL combinations with 6 continuous years
--Between 2016-2021.
--I get 320 firms
DROP VIEW IF EXISTS CEO_6plusyrs;
CREATE VIEW CEO_6plusyrs AS
SELECT 
	gvkey,
	CO_PER_ROL,
	COUNT(*) AS CEO_year
FROM Execucomp
WHERE fyear BETWEEN 2016 AND 2021
	AND CEOANN = 'CEO'
GROUP BY gvkey, CO_PER_ROL
HAVING CEO_year = 6;
	
--Then, merge this with q1.
SELECT *
FROM q1_finalsample
INNER JOIN CEO_6plusyrs
USING (gvkey);


--Q4
--Average FSP for the group with 5 years or less
--1.1%
SELECT 
	AVG(fsp) AS fsp_avg,
	COUNT(*) AS obs
FROM q1_finalsample
INNER JOIN CEO_5yrs
USING (gvkey);



--Q5
--Average FSP for the group with 6+ years
--2.1%
SELECT 
	AVG(fsp) AS fsp_avg,
	COUNT(*) AS obs
FROM q1_finalsample
INNER JOIN CEO_6plusyrs
USING (gvkey);
