# ☕ Cafe Sales Analysis (2023 Dataset)

## 🧾 Description
- This project provides an end-to-end analysis of a 10,000-row cafe sales dataset from 2023. The analysis identifies key business drivers, including monthly revenue trends and sales volume fluctuations throughout the year.
---

## 🍴 Tools Used
- MS Excel
  - Data auditing and cleaning
  - Exploratory data analysis (EDA)
- Tableau
  - Visualization (Interactive dashboard)
---

## 🗃️ Project Strucure
- `data/` → raw dataset (csv file) and cleaned dataset (xlsx file)
  - `cafe_sales_dataset.csv`
  - `cafe_sales_dataset.xlsx`
- `data_cleaning_eda/` → documentation of data cleaning and EDA (txt files)
  - `cafe_sales_data_cleaning.txt`
  - `cafe_sales_eda.txt`
- `visualization`
  - `cafe_sales_visualization_tableau.twbx`
  - `dashboard_preview.png`
- `README.md` → this file with project documentation
---

## 🧹 Data Cleaning 
Please check `cafe_sales_data_cleaning.txt` from the `data_cleaning_eda` folder for full documentation

**Keys Steps Performed during Data Cleaning**
1. Data Overview
   - Check rows and columns
   - Identify missing data
   - Find any typo or inconsistencies with the data
   - Check data format

2. Backup Raw Data
   - Created a duplicate worksheet (working_sheet) to preserve the original raw dataset.
   - Ensures the raw data remains unchanged and allows safe experimentation during the cleaning process.

3: Remove Duplicates
   - Checked for duplicate records across all columns using Excel's Remove Duplicates feature -- No duplicate rows found.

4. Standardize Missing Values (Blanks, "UNKNOWN", "ERROR")
   - Missing or invalid data appeared in multiple formats.
   - Standardized all missing/invalid entries to blank cells.	
   - Ensures consistent handling of missing data during analysis and calculations.

5. Standardize Text and Formats
   - Applied TRIM and PROPER functions
   - Set appropriate number formats to ensure accurate calculations:
   - Applied Short Date format to Transaction Date

6. Handling Missing Data (Blank Values)
   - Price Per Unit Column
     - Identified 533 blank values in the Price Per Unit column.
     - Established Standard Prices using existing valid records.
     - Filled Missing Prices by Item
   - Quantity Column
     - Identified 479 blank values in the Quantity column.
     - Calculated the missing quantity values using available Price Per Unit and Total Spent data (456 rows).
   - Total Spent Column
     - Identified 502 blank values in the Total Spent column.
     - Calculated the missing Total Spent values using available Quantity and Price Per Unit data (479 rows):
   - Item Column
     - Identified 969 blank values in the Item column.
     - Item values were inferred when Price Per Unit uniquely identified an item.
     - Rows with ambiguous prices (3 and 4) were labeled as "Unknown Item".
   - Transaction Date Column
     - Identified 460 blank values in the Transaction Date Column.
     - Sorted Transaction ID and confirmed that it doesn't correlate with chronological order. 
     - Retained 460 records for categorical analysis (Item/Price/Location) but flagged them for exclusion from time-series visualizations to maintain historical accuracy.
   - Payment Method and Location Columns
     - Retained blank values in the Payment Method and Location columns rather than imputing "guessed" data.

7. Final Cleanup Steps
   - Delete rows with missing Total Spent and Price Per Unit (3 rows)
   - Impute Price Per Unit for rows with only Total Spent (Quantity assumed = 1)
   - Remove rows with Price Per Unit but missing both Quantity and Total Spent (20 rows)
