-- STEP 1: Create a backup of the original layoffs table
CREATE TABLE layoffs_backup LIKE layoffs;
INSERT INTO layoffs_backup SELECT * FROM layoffs;

-- STEP 2: Identify duplicate rows using ROW_NUMBER()
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs
)
SELECT * FROM duplicates WHERE row_num > 1;

-- STEP 3: Create a cleaned version of the table and add row_num column
CREATE TABLE layoffs_cleaned LIKE layoffs_backup;
ALTER TABLE layoffs_cleaned ADD COLUMN row_num INT;

-- STEP 4: Insert data into cleaned table with row numbers for duplicates
INSERT INTO layoffs_cleaned
WITH duplicates AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs
)
SELECT * FROM duplicates;

-- STEP 5: Set proper datatype for percentage_laid_off
ALTER TABLE layoffs_cleaned MODIFY COLUMN percentage_laid_off FLOAT;

-- STEP 6: Remove duplicate rows (keep only row_num = 1)
DELETE FROM layoffs_cleaned WHERE row_num > 1;

-- STEP 7: Drop the helper column
ALTER TABLE layoffs_cleaned DROP COLUMN row_num;

-- STEP 8: Check for missing or blank industry values in the original table
SELECT * FROM layoffs WHERE industry IS NULL OR TRIM(industry) = '';

-- STEP 9: Add a new column for cleaned date format
ALTER TABLE layoffs_cleaned ADD COLUMN clean_date DATE;

-- STEP 10: Standardize inconsistent text values
UPDATE layoffs_cleaned SET country = 'United States' WHERE country LIKE 'United State%';
UPDATE layoffs_cleaned SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- STEP 11: Convert string-based date column to DATE format
UPDATE layoffs_cleaned SET clean_date = STR_TO_DATE(date, '%m/%d/%Y');

-- STEP 12: Replace original 'date' column with cleaned version
ALTER TABLE layoffs_cleaned DROP COLUMN date;
ALTER TABLE layoffs_cleaned RENAME COLUMN clean_date TO date;

-- STEP 13: Trim whitespace from string columns
UPDATE layoffs_cleaned SET company = TRIM(company);
UPDATE layoffs_cleaned SET location = TRIM(location);
UPDATE layoffs_cleaned SET industry = TRIM(industry);
UPDATE layoffs_cleaned SET country = TRIM(country);

-- STEP 14: Set empty strings in industry column to NULL
UPDATE layoffs_cleaned SET industry = NULL WHERE industry = '';

-- STEP 15: Fill missing industry values based on same company
UPDATE layoffs_cleaned t1
JOIN layoffs_cleaned t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- STEP 16: Final null check
SELECT * FROM layoffs_cleaned WHERE industry IS NULL OR TRIM(industry) = '';

-- STEP 17: View the final cleaned data
SELECT * FROM layoffs_cleaned;
