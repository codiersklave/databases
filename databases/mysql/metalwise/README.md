# Database Schema for `precmet`

## Overview

This schema contains tables, triggers, and views for managing product pricing, purchases, and their historical versions. The main tables are `price`, `product`, and `purchase`. Each of these tables has a corresponding historical table that stores versions of the records (`_price`, `_product`, `_purchase`).

## Table Structure

### `price`
This table stores the price information of products.

| Column          | Type              | Description                                     |
|-----------------|-------------------|-------------------------------------------------|
| `id`            | int unsigned      | Primary Key                                     |
| `_v`            | int unsigned      | Version column for optimistic locking           |
| `product_id`    | int unsigned      | Foreign Key referencing `product` table         |
| `date`          | datetime          | Date when the price is recorded                 |
| `price_in_cents`| int unsigned      | Price of the product in cents                   |
| `created`       | datetime          | Timestamp when the record is created            |
| `updated`       | datetime          | Timestamp when the record is updated            |
| `deleted`       | datetime          | Timestamp when the record is marked as deleted  |

### `_price`
This table stores historical versions of price records.

| Column          | Type              | Description                                     |
|-----------------|-------------------|-------------------------------------------------|
| `id`            | int unsigned      | Price id                                        |
| `_v`            | int unsigned      | Version number                                  |
| `product_id`    | int unsigned      | Foreign Key referencing `product` table         |
| `date`          | datetime          | Date when the price is recorded                 |
| `price_in_cents`| int unsigned      | Price of the product in cents                   |
| `created`       | datetime          | Timestamp when the record is created            |
| `updated`       | datetime          | Timestamp when the record is updated            |
| `deleted`       | datetime          | Timestamp when the record is marked as deleted  |

### `product`
This table stores product information.

| Column     | Type              | Description                                     |
|------------|-------------------|-------------------------------------------------|
| `id`       | int unsigned      | Primary Key                                     |
| `_v`       | int unsigned      | Version column for optimistic locking           |
| `parent_id`| int unsigned      | Parent product id, represents hierarchy         |
| `name`     | varchar(255)      | Name of the product                             |
| `multiplier`| float unsigned   | Multiplier for the product                      |
| `created`  | datetime          | Timestamp when the record is created            |
| `updated`  | datetime          | Timestamp when the record is updated            |
| `deleted`  | datetime          | Timestamp when the record is marked as deleted  |

### `_product`
This table stores historical versions of product records.

| Column     | Type              | Description                                     |
|------------|-------------------|-------------------------------------------------|
| `id`       | int unsigned      | Product id                                      |
| `_v`       | int unsigned      | Version number                                  |
| `parent_id`| int unsigned      | Parent product id                               |
| `name`     | varchar(255)      | Name of the product                             |
| `multiplier`| float unsigned   | Multiplier for the product                      |
| `created`  | datetime          | Timestamp when the record is created            |
| `updated`  | datetime          | Timestamp when the record is updated            |
| `deleted`  | datetime          | Timestamp when the record is marked as deleted  |

### `purchase`
This table stores information about purchases.

| Column                | Type              | Description                                     |
|-----------------------|-------------------|-------------------------------------------------|
| `id`                  | int unsigned      | Primary Key                                     |
| `_v`                  | int unsigned      | Version column for optimistic locking           |
| `product_id`          | int unsigned      | Foreign Key referencing `product` table         |
| `date`                | date              | Date of the purchase                            |
| `quantity`            | int unsigned      | Quantity of the product purchased               |
| `total_price_in_cents`| int unsigned      | Total price of the purchase in cents            |
| `included_costs_in_cents`| int unsigned   | Included additional costs in cents              |
| `created`             | datetime          | Timestamp when the record is created            |
| `updated`             | datetime          | Timestamp when the record is updated            |
| `deleted`             | datetime          | Timestamp when the record is marked as deleted  |

### `_purchase`
This table stores historical versions of purchase records.

| Column                | Type              | Description                                     |
|-----------------------|-------------------|-------------------------------------------------|
| `id`                  | int unsigned      | Purchase id                                     |
| `_v`                  | int unsigned      | Version number                                  |
| `product_id`          | int unsigned      | Foreign Key referencing `product` table         |
| `date`                | date              | Date of the purchase                            |
| `quantity`            | int unsigned      | Quantity of the product purchased               |
| `total_price_in_cents`| int unsigned      | Total price of the purchase in cents            |
| `included_costs_in_cents`| int unsigned   | Included additional costs in cents              |
| `created`             | datetime          | Timestamp when the record is created            |
| `updated`             | datetime          | Timestamp when the record is updated            |
| `deleted`             | datetime          | Timestamp when the record is marked as deleted  |

## Triggers

### Price Triggers

- **price_before_update**: Increments `_v` version number before updating in the `price` table.
- **price_after_update**: Inserts the old record into `_price` table storing the historical version after updating in the `price` table.
- **price_before_delete**: Prevents deletion of records from the `price` table, suggesting setting the `deleted` column instead.
- **price_after_delete**: Resets the deletion flag after a deletion operation in the `price` table.

### Product Triggers

- **product_before_update**: Increments `_v` version number before updating in the `product` table.
- **product_after_update**: Inserts the old record into `_product` table storing the historical version after updating in the `product` table.
- **product_before_delete**: Prevents deletion of records from the `product` table, suggesting setting the `deleted` column instead.
- **product_after_delete**: Resets the deletion flag after a deletion operation in the `product` table.

### Purchase Triggers

- **purchase_before_update**: Increments `_v` version number before updating in the `purchase` table.
- **purchase_after_update**: Inserts the old record into `_purchase` table storing the historical version after updating in the `purchase` table.
- **purchase_before_delete**: Prevents deletion of records from the `purchase` table, suggesting setting the `deleted` column instead.
- **purchase_after_delete**: Resets the deletion flag after a deletion operation in the `purchase` table.

## Views

### `avg_prices_non_root_products`

This view calculates average prices for non-root products, along with their total quantities, multipliers, and parent product details.

### `avg_prices_root_products`

This view calculates average prices for root products using the data from `avg_prices_non_root_products`.

### `current_values_root_products`

This view shows the current prices of root products and the difference between their current prices and average prices.

### `current_values_non_root_products`

This view shows the current prices of non-root products and the difference between their current prices and average prices.

## Examples

### Query to Get Average Prices of Non-Root Products

```mysql
SELECT * FROM avg_prices_non_root_products;
```

### Query to Get Average Prices of Root Products

```mysql
SELECT * FROM avg_prices_root_products;
```

### Query to Get Current Prices and Differences for Root Products

```mysql
SELECT * FROM current_values_root_products;
```

### Query to Get Current Prices and Differences for Non-Root Products

```mysql
SELECT * FROM current_values_non_root_products;
```

### Inserting a New Price Record

```mysql
INSERT INTO price (product_id, date, price_in_cents) 
VALUES (1, '2023-10-01 12:00:00', 1000);
```

### Updating a Product Record

```mysql
UPDATE product 
SET name = 'Updated Product Name' 
WHERE id = 1;
```

### Deleting a Purchase (This will fail and suggest marking `deleted` instead)

```mysql
DELETE FROM purchase WHERE id = 1;
```

## Notes

- The triggers prevent direct deletions and enforce versioning.
- Use the `_v` field to manage optimistic concurrency.
- The views provide useful insights into pricing and purchase trends.