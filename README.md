# database-printlab

Initial SQL schema for creating a PrintLab database.

## Files

- `schema.sql` - DDL script to create core PrintLab tables, constraints, and indexes.

## Database entities

The schema includes:

- `customers` - customer master data
- `staff` - employee/staff data
- `print_products` - printable product catalog
- `print_jobs` - customer print orders
- `job_items` - line items under each print job
- `payments` - payment records per job

## Create the database (SQLite)

```bash
sqlite3 printlab.db < schema.sql
```
