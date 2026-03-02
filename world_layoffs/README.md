# 📉 World Layoffs Analysis

**Status:** Ongoing 🔄️

## 🔎 Description
- This project focuses on cleaning and analyzing a global layoffs dataset using MySQL to perform structured exploratory data analysis (EDA).
- The analysis covers layoff events from 2020 to 2026, identifying patterns in workforce reductions and economic cycles.
---

## 🛠 Tools Used
- MySQL (CTEs, Window Functions, Aggregations)
- CSV Dataset
---

## 🗃️ Project Structure
- `data/` → raw and cleaned CSV files
  - `layoffs_raw.csv`
  - `layoffs_cleaned.csv`
- `sql/` → SQL scripts for data cleaning and exploratory analysis
  -  `layoffs_data_cleaning.sql`
  -  `layoffs_exploratory_data_analysis.sql`
- `README.md` → this file with project documentation
---

## 🧹 Data Cleaning (SQL)

**Key steps performed in the SQL script:**
1. Created staging tables to preserve the raw data
2. Removed duplicate records
3. Standardized data by removing extra spaces, correcting inconsistencies, and fixing typos
4. Converted data types
5. Handled blank and NULL values
6. Saved the final cleaned dataset as `layoffs_cleaned.csv`

After cleaning:
- Raw records: 4,299
- Cleaned records: 3,594
- Removed: 705 records

> SQL script: 📝 `sql/layoffs_data_cleaning.sql`

---

## 📊 Exploratory Data Analysis (EDA)

**The analysis was structured into the following sections:**
1. Structure Overview
2. Time Coverage
3. Overall Impact
4. Company Analysis
5. Industry Analysis
6. Geographic Analysis
7. Stage & Funding Analysis
8. Extreme Cases
9. Trend Analysis
10. Key Insights Summary

### 💡Key Insights
- The dataset has 3,594 layoff events from 2,481 companies, covering 2020 to 2026. Total layoffs worldwide are 829,853.
- Most layoffs happened in the United States, especially in the SF Bay Area and Seattle.
- Retail, Hardware, and Consumer industries had the most layoffs.
- Big companies, especially Post-IPO and those with over $1B funding, had the largest layoffs.
- Some extreme cases show companies laying off 100% of their workforce, mostly in Healthcare, Retail, and Food.
- Yearly trend:
  - 2021: big drop in layoffs (-80%)
  - 2022: huge increase (+938%)
  - 2023: peak layoffs (264,320)
  - 2024–2026: layoffs gradually went down
- Overall pattern: layoffs spike in certain years and industries, then slowly decrease, showing a cycle.
--- 

## 🚀 Next Steps

- Add visualizations to complement SQL EDA:
  - Trend lines for yearly layoffs
  - Bar charts for top industries and countries
  - Visuals for funding stage and extreme cases

## 📌 Dataset Source
- Global layoffs dataset obtained from: [Kaggle: Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
