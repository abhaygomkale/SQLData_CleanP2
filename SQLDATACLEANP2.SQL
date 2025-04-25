-- First, import your data into a table named 'layoffs'
-- Ensure your CSV is loaded in MySQL Workbench or use the import wizard

-- Creating a backup table to preserve original data
CREATE TABLE lfc LIKE layoffs;
INSERT INTO lfc SELECT * FROM layoffs;

-- Viewing the backup table
SELECT * FROM lfc;

-- Identifying duplicate rows using ROW_NUMBER()
WITH DUPLI AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS RWN
    FROM layoffs
)
SELECT * FROM DUPLI WHERE RWN > 1;

-- Creating a cleaned version of the backup table with an extra column for row number
CREATE TABLE lfc2 LIKE lfc;
ALTER TABLE lfc2 ADD COLUMN RW_n INT;

-- Inserting data along with row number for identifying duplicates
INSERT INTO lfc2
WITH DUPLI AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS RWN
    FROM layoffs
)
SELECT * FROM DUPLI;

-- Ensuring the percentage_laid_off column has appropriate data type
ALTER TABLE lfc2 MODIFY COLUMN percentage_laid_off FLOAT;

-- Deleting duplicate rows based on row number
DELETE FROM lfc2 WHERE RW_n > 1;

-- Dropping the helper column used for duplicate detection
ALTER TABLE lfc2 DROP COLUMN RW_n;

-- Checking rows where industry column is missing or blank
SELECT * FROM layoffs WHERE industry IS NULL OR industry = '';

-- Adding a new column for cleaned date format
ALTER TABLE lfc2 ADD COLUMN CLEAN_DATE DATE;

-- Standardizing country and industry values
UPDATE lfc2 SET country = 'United States' WHERE country LIKE 'United State%';
UPDATE lfc2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- Converting text-based date column to proper date format
UPDATE lfc2 SET CLEAN_DATE = STR_TO_DATE(date, '%m/%d/%Y');

-- Replacing original date column with the cleaned one
ALTER TABLE lfc2 DROP COLUMN date;
ALTER TABLE lfc2 RENAME COLUMN CLEAN_DATE TO date;

-- Trimming unnecessary whitespace from text fields
UPDATE lfc2 SET company = TRIM(company);
UPDATE lfc2 SET location = TRIM(location);
UPDATE lfc2 SET industry = TRIM(industry);
UPDATE lfc2 SET country = TRIM(country);

-- Setting empty industry values to NULL for consistency
UPDATE lfc2 SET industry = NULL WHERE industry = "";

-- Filling missing industry values based on the same company
UPDATE lfc2 t1
JOIN lfc2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Final null check on industry column
SELECT * FROM lfc2 WHERE industry IS NULL OR industry = '';

-- Final cleaned dataset
SELECT * FROM lfc2;


