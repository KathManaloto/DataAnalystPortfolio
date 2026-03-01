# 📉 World Layoffs Analysis

**Status:** Ongoing 🔄️

**Description:**
- This project focuses on cleaning and analyzing a global layoffs dataset using SQL.
- The cleaned data is prepared for Exploratory Data Analysis (EDA) and visualization to uncover trends in layoffs across different industries and countries.

---

## 🗃️ Project Structure
- `data/` → raw and cleaned CSV files (`layoffs_raw.csv` and `layoffs_cleaned.csv`)
- `sql/` → SQL data cleaning script (`layoffs_data_cleaning.sql`)
- `README.md` → this file with project documentation

---

## 🧹 Data Cleaning (SQL)

**Key steps performed in the SQL script:**
1. Created staging tables to preserve the raw data
2. Removed duplicate records
3. Standardized data by removing extra spaces, correcting inconsistencies, and fixing typos
4. Converted data types for respective columns
5. Handled blank and NULL values
6. Saved the final cleaned dataset as `layoffs_cleaned.csv`

> SQL script: 📝 `sql/layoffs_data_cleaning.sql`

---

## 📊 Exploratory Data Analysis (EDA)

Next steps (project ongoing):  
1. Analyze trends in layoffs by industry, country, and stage  
2. Create visualizations (line charts, bar charts, heatmaps)  
3. Document insights and observations

--- 

## 📌 Dataset Source
- Global layoffs dataset obtained from: [Kaggle: Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
