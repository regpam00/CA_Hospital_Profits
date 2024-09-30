-- Created in Microsoft VS Code using MySQL extension
CREATE DATABASE california_hosp;

-- Create table
CREATE TABLE profitability (
profit_year YEAR,
facility_number INTEGER, 
facility_name VARCHAR(70),
begin_date VARCHAR(13),
end_date VARCHAR(13),
county_name VARCHAR(15),
control_type VARCHAR(11),
income_stmnt_item VARCHAR(16),
income_stmnt_amount FLOAT(14,2),
patient_day_rate INTEGER
);

-- Check if the local_infile is disabled or enabled
SHOW GLOBAL variables LIKE 'local_infile';

SET GLOBAL local_infile = TRUE;
SHOW VARIABLES WHERE Variable_Name LIKE "%dir";

-- Load data from csv file using Windows
LOAD DATA LOCAL INFILE '\\California Hospitals\\hospital-profitability-2009-2013-.csv'
INTO TABLE profitability
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
('Year', 'Facility Number',	'Facility Name', 'Begin Date', 'End Date', 'County Name', 'Type of Control', 'Income Statement Item', 'Income Statement Amount', 'Amount per Adjusted Patient Day');


LOAD DATA LOCAL INFILE 'C:\\Users\\Regine Pamphile\\Desktop\\Practice SQL\\hospital-profitability-2009-2013-.csv'
INTO TABLE profitability
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE profitability SET facility_number = 000000000 WHERE facility_number = '';
UPDATE profitability SET facility_name = 'null' WHERE facility_name = '';
UPDATE profitability SET begin_date = 'null' WHERE begin_date = ''; -- change this from '' to NULL, not 'null' in final version
UPDATE profitability SET end_date = 'null' WHERE end_date = ''; -- change this from '' to NULL, not 'null' in final version
UPDATE profitability SET control_type = 'null' WHERE control_type = '';

UPDATE profitability SET income_stmnt_amount = 0 WHERE income_stmnt_amount = '';
UPDATE profitability SET patient_day_rate = 0 WHERE patient_day_rate = '';

UPDATE profitability SET begin_date = DATE_FORMAT(STR_TO_DATE(begin_date, '%m/%d/%Y'), '%Y-%m-%d') WHERE begin_date <> 'null'; 
UPDATE profitability SET end_date = DATE_FORMAT(STR_TO_DATE(end_date, '%m/%d/%Y'), '%Y-%m-%d') WHERE end_date <> 'null';

UPDATE profitability SET begin_date = NULL WHERE begin_date = 'null';
UPDATE profitability SET end_date = NULL WHERE end_date = 'null';

ALTER TABLE profitability MODIFY COLUMN begin_date DATE;
ALTER TABLE profitability MODIFY COLUMN end_date DATE;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM profitability;

'''Number of entries''' 
SELECT COUNT(*) FROM profitability;

'''Number of entries per year'''
SELECT profit_year, COUNT(*) AS 'counts' FROM profitability GROUP BY profit_year; --excludes statewide values

'''Number of entries per county'''
SELECT county_name, COUNT(*) AS 'counts' FROM profitability GROUP BY county_name ORDER BY county_name;
SELECT county_name, COUNT(*) AS 'counts' FROM profitability WHERE county_name <> 'Statewide' GROUP BY county_name ORDER BY county_name;

'''Number of entries per contro type'''
SELECT control_type, COUNT(*) AS 'counts' FROM profitability WHERE control_type <> 'null' GROUP BY control_type ORDER BY control_type;

'''Finds total revenue and cost for each hospital, excludes statewide values'''

-- SELECT profit_year, facility_number, facility_name, control_type, 
-- SUM(CASE 
--     WHEN income_stmnt_item = "GR_PT_REV" THEN income_stmnt_amount 
--     WHEN income_stmnt_item = "TOT_CAP_REV" THEN income_stmnt_amount
--     WHEN income_stmnt_item = "OTH_OP_REV" THEN income_stmnt_amount
--     WHEN income_stmnt_item = "NONOP_REV" THEN income_stmnt_amount
--     ELSE NULL END) AS 'revenue',
-- SUM(CASE 
--     WHEN income_stmnt_item = "DED_REV_PLUS_DSH" THEN income_stmnt_amount 
--     WHEN income_stmnt_item = "INC_TAX" THEN income_stmnt_amount
--     WHEN income_stmnt_item = "NONOP_EXP" THEN income_stmnt_amount
--     WHEN income_stmnt_item = "TOT_OP_EXP" THEN income_stmnt_amount
--     WHEN income_stmnt_item = "EXT_ITEM" THEN income_stmnt_amount
--     ELSE NULL END) AS "cost"
--     FROM profitability WHERE facility_number <> 0
--     GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name;

-- SELECT profit_year, facility_number, facility_name, control_type, 
--        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV") THEN income_stmnt_amount ELSE 0 END) AS revenue,
--        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") THEN income_stmnt_amount ELSE 0 END) AS cost
-- FROM profitability 
-- WHERE facility_number <> 0
-- GROUP BY profit_year, facility_number, facility_name, control_type 
-- ORDER BY profit_year, facility_name;

SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, control_type 
ORDER BY profit_year, facility_name;

'''Finds total revenue, cost and profit for each hospital'''

-- SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
--     (SELECT profit_year, facility_number, facility_name, control_type, 
--         SUM(CASE 
--             WHEN income_stmnt_item = "GR_PT_REV" THEN income_stmnt_amount 
--             WHEN income_stmnt_item = "TOT_CAP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "OTH_OP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "NONOP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "EXT_ITEM"  AND income_stmnt_amount >= 0 THEN income_stmnt_amount
--             ELSE NULL END) AS "revenue",
--         SUM(CASE 
--             WHEN income_stmnt_item = "DED_REV_PLUS_DSH" THEN income_stmnt_amount 
--             WHEN income_stmnt_item = "INC_TAX" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "NONOP_EXP" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "TOT_OP_EXP" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "EXT_ITEM" AND income_stmnt_amount < 0 THEN income_stmnt_amount
--             ELSE NULL END) AS "cost"
--             FROM profitability WHERE facility_number <> 0
--             GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
-- GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name;

SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, control_type 
ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name;


'''Average revenue, cost and profits for each profit year'''

-- SELECT s.profit_year, ROUND(AVG(s.revenue), 0) AS "avg_revenue", ROUND(AVG(s.cost), 0) AS "avg_cost", ROUND(AVG(s.profit), 0) AS "avg_profit" 
-- FROM (
--     SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
--     (SELECT profit_year, facility_number, facility_name, control_type, 
--         SUM(CASE 
--             WHEN income_stmnt_item = "GR_PT_REV" THEN income_stmnt_amount 
--             WHEN income_stmnt_item = "TOT_CAP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "OTH_OP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "NONOP_REV" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "EXT_ITEM"  AND income_stmnt_amount >= 0 THEN income_stmnt_amount
--             ELSE NULL END) AS "revenue",
--         SUM(CASE 
--             WHEN income_stmnt_item = "DED_REV_PLUS_DSH" THEN income_stmnt_amount 
--             WHEN income_stmnt_item = "INC_TAX" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "NONOP_EXP" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "TOT_OP_EXP" THEN income_stmnt_amount
--             WHEN income_stmnt_item = "EXT_ITEM" AND income_stmnt_amount < 0 THEN income_stmnt_amount
--             ELSE NULL END) AS "cost"
--             FROM profitability WHERE facility_number <> 0
--             GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
-- GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name
-- )s GROUP BY s.profit_year ORDER BY s.profit_year;

SELECT s.profit_year, ROUND(AVG(s.revenue), 0) AS "avg_revenue", ROUND(AVG(s.cost), 0) AS "avg_cost", ROUND(AVG(s.profit), 0) AS "avg_profit" 
FROM (
    SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, control_type 
ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name
)s GROUP BY s.profit_year ORDER BY s.profit_year;


'''Find the facilities with maximum and minimum revenues'''
SELECT s.profit_year, MAX(s.revenue) AS "max_rev_value", MIN(s.revenue) AS "min_rev_value" FROM 
    (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
            THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
            THEN income_stmnt_amount ELSE 0 END) AS cost
        FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
GROUP BY s.profit_year ORDER BY s.profit_year;


'''Facilities with max values per year'''
SELECT v.profit_year, m.facility_number, m.facility_name, v.max_rev_value 
FROM (SELECT s.profit_year, MAX(s.revenue) AS "max_rev_value", MIN(s.revenue) AS "min_rev_value" FROM 
    (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
            THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
            THEN income_stmnt_amount ELSE 0 END) AS cost
        FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
GROUP BY s.profit_year ORDER BY s.profit_year)v 
JOIN 
(SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
            THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
            THEN income_stmnt_amount ELSE 0 END) AS cost
        FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)m 
ON m.revenue = v.max_rev_value GROUP BY v.profit_year, m.facility_number, m.facility_name, v.max_rev_value  ORDER BY v.profit_year;


'''Facilities with min values per year'''
SELECT v.profit_year, m.facility_number, m.facility_name, v.min_rev_value 
FROM (SELECT s.profit_year, MAX(s.revenue) AS "max_rev_value", MIN(s.revenue) AS "min_rev_value" FROM 
    (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
            THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
            THEN income_stmnt_amount ELSE 0 END) AS cost
        FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
GROUP BY s.profit_year ORDER BY s.profit_year)v 
JOIN 
(SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
            THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
            THEN income_stmnt_amount ELSE 0 END) AS cost
        FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)m 
ON m.revenue = v.min_rev_value GROUP BY v.profit_year, m.facility_number, m.facility_name, v.min_rev_value  ORDER BY v.profit_year;


''' Revenue per control'''
SELECT b.profit_year AS "yearly_revenue",
SUM(CASE WHEN b.control_type = 'District' THEN revenue ELSE 0 END) AS "District",
SUM(CASE WHEN b.control_type = 'Non-Profit' THEN revenue ELSE 0 END) AS "Non_Profit",
SUM(CASE WHEN b.control_type = 'City/County' THEN revenue ELSE 0 END) AS "City_or_County",
SUM(CASE WHEN b.control_type = 'Investor' THEN revenue ELSE 0 END) AS "Investor",
SUM(CASE WHEN b.control_type = 'State' THEN revenue ELSE 0 END) AS "State" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
    FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type 
    ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)b GROUP BY b.profit_year ORDER BY b.profit_year;

''' Cost per control'''
SELECT b.profit_year AS "yearly_cost",
SUM(CASE WHEN b.control_type = 'District' THEN cost ELSE 0 END) AS "District",
SUM(CASE WHEN b.control_type = 'Non-Profit' THEN cost ELSE 0 END) AS "Non_Profit",
SUM(CASE WHEN b.control_type = 'City/County' THEN cost ELSE 0 END) AS "City_or_County",
SUM(CASE WHEN b.control_type = 'Investor' THEN cost ELSE 0 END) AS "Investor",
SUM(CASE WHEN b.control_type = 'State' THEN cost ELSE 0 END) AS "State" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
    FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type 
    ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)b GROUP BY b.profit_year ORDER BY b.profit_year;


''' Profit per control'''
SELECT b.profit_year AS "yearly_profit",
SUM(CASE WHEN b.control_type = 'District' THEN profit ELSE 0 END) AS "District",
SUM(CASE WHEN b.control_type = 'Non-Profit' THEN profit ELSE 0 END) AS "Non_Profit",
SUM(CASE WHEN b.control_type = 'City/County' THEN profit ELSE 0 END) AS "City_or_County",
SUM(CASE WHEN b.control_type = 'Investor' THEN profit ELSE 0 END) AS "Investor",
SUM(CASE WHEN b.control_type = 'State' THEN profit ELSE 0 END) AS "State" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
    FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type 
    ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)b GROUP BY b.profit_year ORDER BY b.profit_year;


''' Data per county per year highest to lowest profit'''

'2009'
SELECT t.profit_year, t.county_name, SUM(t.revenue) AS "rev_sum", SUM(t.cost) AS "cost_sum", SUM(t.revenue-t.cost) AS "profit_sum" FROM 
    (SELECT profit_year, facility_number, facility_name, county_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, county_name, control_type 
ORDER BY profit_year, facility_name)t WHERE t.profit_year = '2009'
GROUP BY t.profit_year, t.county_name ORDER BY t.profit_year, SUM(t.revenue-t.cost) DESC;

'2010'
SELECT t.profit_year, t.county_name, SUM(t.revenue) AS "rev_sum", SUM(t.cost) AS "cost_sum", SUM(t.revenue-t.cost) AS "profit_sum" FROM 
    (SELECT profit_year, facility_number, facility_name, county_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, county_name, control_type 
ORDER BY profit_year, facility_name)t WHERE t.profit_year = '2010'
GROUP BY t.profit_year, t.county_name ORDER BY t.profit_year, SUM(t.revenue-t.cost) DESC;

'2011'
SELECT t.profit_year, t.county_name, SUM(t.revenue) AS "rev_sum", SUM(t.cost) AS "cost_sum", SUM(t.revenue-t.cost) AS "profit_sum" FROM 
    (SELECT profit_year, facility_number, facility_name, county_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, county_name, control_type 
ORDER BY profit_year, facility_name)t WHERE t.profit_year = '2011'
GROUP BY t.profit_year, t.county_name ORDER BY t.profit_year, SUM(t.revenue-t.cost) DESC;

'2012'
SELECT t.profit_year, t.county_name, SUM(t.revenue) AS "rev_sum", SUM(t.cost) AS "cost_sum", SUM(t.revenue-t.cost) AS "profit_sum" FROM 
    (SELECT profit_year, facility_number, facility_name, county_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, county_name, control_type 
ORDER BY profit_year, facility_name)t WHERE t.profit_year = '2012'
GROUP BY t.profit_year, t.county_name ORDER BY t.profit_year, SUM(t.revenue-t.cost) DESC;

'2013'
SELECT t.profit_year, t.county_name, SUM(t.revenue) AS "rev_sum", SUM(t.cost) AS "cost_sum", SUM(t.revenue-t.cost) AS "profit_sum" FROM 
    (SELECT profit_year, facility_number, facility_name, county_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, county_name, control_type 
ORDER BY profit_year, facility_name)t WHERE t.profit_year = '2013'
GROUP BY t.profit_year, t.county_name ORDER BY t.profit_year, SUM(t.revenue-t.cost) DESC;


''' Percentage of revenue for each year'''
SELECT s.profit_year, SUM(s.revenue) AS "revenue_sum", ROUND((SUM(s.revenue)*100)/b.sum, 2) AS "revenue_%", ROUND(SUM(SUM(s.revenue)*100/b.sum) OVER (ORDER BY s.profit_year), 2) AS "cumul_revenue_%"
FROM 
(SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
JOIN 
(SELECT SUM(t.revenue) AS "sum" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t)b 
GROUP BY s.profit_year, b.sum ORDER BY s.profit_year;


''' Percentage of cost for each year'''
SELECT s.profit_year, SUM(s.cost) AS "product_sum", ROUND((SUM(s.cost)*100)/b.sum, 2) AS "cost_%", ROUND(SUM(SUM(s.cost)*100/b.sum) OVER (ORDER BY s.profit_year), 2) AS "cumul_cost_%"
FROM 
(SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
JOIN 
(SELECT SUM(t.cost) AS "sum" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t)b 
GROUP BY s.profit_year, b.sum ORDER BY s.profit_year;


''' Percentage of profits for each year'''
SELECT s.profit_year, SUM(s.profit) AS "product_sum", ROUND((SUM(s.profit)*100)/b.sum, 2) AS "profit_%", ROUND(SUM(SUM(s.profit)*100/b.sum) OVER (ORDER BY s.profit_year), 2) AS "cumul_profit_%"
FROM 
(SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
    GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name)s 
JOIN 
(SELECT SUM(t.revenue-t.cost) AS "sum" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
    THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
    THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 GROUP BY profit_year, facility_number, facility_name, control_type ORDER BY profit_year, facility_name)t)b 
GROUP BY s.profit_year, b.sum ORDER BY s.profit_year;


--Quarterly earnings Q1, Q2, Q3, Q4 with revenue 

SELECT DISTINCT begin_date, QUARTER(begin_date) FROM profitability WHERE begin_date <> 0;

SELECT w.profit_year, 
SUM(CASE WHEN QUARTER(w.begin_date) = 1 THEN w.revenue ELSE 0 END) AS "Q1_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 2 THEN w.revenue ELSE 0 END) AS "Q2_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 3 THEN w.revenue ELSE 0 END) AS "Q3_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 4 THEN w.revenue ELSE 0 END) AS "Q4_earnings" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit", t.begin_date, t.end_date FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, begin_date, end_date, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type, begin_date, end_date ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.begin_date, t.end_date ORDER BY t.profit_year, t.facility_name)w 
WHERE w.begin_date <> 0 GROUP BY w.profit_year ORDER BY w.profit_year;


--Quarterly earnings Q1, Q2, Q3, Q4 with revenue (percentages)

SELECT w.profit_year, 
SUM(CASE WHEN QUARTER(w.begin_date) = 1 THEN CAST((w.revenue*100)/r.rev_sum AS DECIMAL (5,3)) ELSE 0 END) AS "Q1_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 2 THEN CAST((w.revenue*100)/r.rev_sum AS DECIMAL (5,3)) ELSE 0 END) AS "Q2_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 3 THEN CAST((w.revenue*100)/r.rev_sum AS DECIMAL (5,3)) ELSE 0 END) AS "Q3_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 4 THEN CAST((w.revenue*100)/r.rev_sum AS DECIMAL (5,3)) ELSE 0 END) AS "Q4_earnings" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit", t.begin_date, t.end_date FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, begin_date, end_date, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type, begin_date, end_date ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.begin_date, t.end_date ORDER BY t.profit_year, t.facility_name)w 
JOIN 
(SELECT s.profit_year, SUM(s.revenue) AS "rev_sum"
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit" FROM 
    (SELECT profit_year, facility_number, facility_name, control_type, 
    SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
    SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost
FROM profitability WHERE facility_number <> 0 
GROUP BY profit_year, facility_number, facility_name, control_type 
ORDER BY profit_year, facility_name)t
GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost ORDER BY t.profit_year, t.facility_name
)s GROUP BY s.profit_year ORDER BY s.profit_year)r
WHERE w.begin_date <> 0 AND r.profit_year = w.profit_year GROUP BY w.profit_year, r.rev_sum ORDER BY w.profit_year;


--Annual revenue growth rate
SELECT 
d.profit_year, CONCAT(ROUND(((d.Q4_earnings-d.Q1_earnings)*100)/d.Q1_earnings, 2), "%") AS "annual_rev_growth_rate"
FROM (SELECT w.profit_year, 
SUM(CASE WHEN QUARTER(w.begin_date) = 1 THEN w.revenue ELSE 0 END) AS "Q1_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 2 THEN w.revenue ELSE 0 END) AS "Q2_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 3 THEN w.revenue ELSE 0 END) AS "Q3_earnings",
SUM(CASE WHEN QUARTER(w.begin_date) = 4 THEN w.revenue ELSE 0 END) AS "Q4_earnings" 
FROM (SELECT t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.revenue-t.cost AS "profit", t.begin_date, t.end_date FROM 
        (SELECT profit_year, facility_number, facility_name, control_type, begin_date, end_date, 
        SUM(CASE WHEN income_stmnt_item IN ("GR_PT_REV", "TOT_CAP_REV", "OTH_OP_REV", "NONOP_REV", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount >= 0) 
        THEN income_stmnt_amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN income_stmnt_item IN ("DED_REV_PLUS_DSH", "INC_TAX", "NONOP_EXP", "TOT_OP_EXP", "EXT_ITEM") AND (income_stmnt_item <> "EXT_ITEM" OR income_stmnt_amount < 0) 
        THEN income_stmnt_amount ELSE 0 END) AS cost FROM profitability WHERE facility_number <> 0 
        GROUP BY profit_year, facility_number, facility_name, control_type, begin_date, end_date ORDER BY profit_year, facility_name)t
    GROUP BY t.profit_year, t.facility_number, t.facility_name, t.control_type, t.revenue, t.cost, t.begin_date, t.end_date ORDER BY t.profit_year, t.facility_name)w 
WHERE w.begin_date <> 0 GROUP BY w.profit_year ORDER BY w.profit_year)d;



