# SQL Retail Analytics — Practice Project (PostgreSQL)

Simple retail dataset (customers, products, orders, order_items) for SQL analytics practice.

## Structure
```
sql-data-exploration/
├─ data/                # CSV datasets
├─ sql/                 # SQL schema, load, tasks, and solutions
└─ README.md
```

## How to Use
Create a PostgreSQL database (e.g., `retail_analytics`), then run in pgAdmin or psql:
```sql
\i sql/00_schema_postgres.sql
\i sql/01_load_csv.sql
\i sql/03_solutions.sql
```

## Notes
- Revenue includes only rows where `orders.status = 'completed'`.
- Discounts are already applied in `order_items.unit_price`.
- Dates cover 2024–2025; YTD ends at 2025-10-27.

## Expected Outputs (sanity check)
- Total revenue YTD 2025 ≈ 19722.65
- AOV 2025 ≈ 84.28
- Returning customer rate 2025 ≈ 90.91%
- Top product (all-time): LED Monitor — 8496.00

Author: Shahrzad Ali Khani Nejad
