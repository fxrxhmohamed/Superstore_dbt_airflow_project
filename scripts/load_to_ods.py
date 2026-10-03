from pathlib import Path
import duckdb

PROJECT_ROOT = Path(__file__).resolve().parent.parent

DB_PATH = PROJECT_ROOT / "dbt_project" / "dev.duckdb"
XLSX_PATH = PROJECT_ROOT / "data" / "raw" / "Superstore.xlsx"

con = duckdb.connect(str(DB_PATH))

con.execute("INSTALL excel")
con.execute("LOAD excel")

con.execute("CREATE SCHEMA IF NOT EXISTS ods")

con.execute(f"""
    CREATE OR REPLACE TABLE ods.raw_superstore AS
    SELECT
        "Row ID"        AS row_id,
        "Order ID"      AS order_id,
        "Order Date"    AS order_date,
        "Ship Date"     AS ship_date,
        "Ship Mode"     AS ship_mode,
        "Customer ID"   AS customer_id,
        "Customer Name" AS customer_name,
        "Segment"       AS segment,
        "Country"       AS country,
        "City"          AS city,
        "State"         AS state,
        "Postal Code"   AS postal_code,
        "Region"        AS region,
        "Product ID"    AS product_id,
        "Category"      AS category,
        "Sub-Category"  AS sub_category,
        "Product Name"  AS product_name,
        "Sales"         AS sales,
        "Quantity"      AS quantity,
        "Discount"      AS discount,
        "Profit"        AS profit
    FROM read_xlsx('{XLSX_PATH.as_posix()}', sheet = 'Sample - Superstore')
""")

count = con.execute("SELECT COUNT(*) FROM ods.raw_superstore").fetchone()[0]
print(f"Loaded ods.raw_superstore: {count} rows")

con.close()
print("ODS load complete")