# Project 1: Inventory-and-Warehouse-Management-System
Author- Darji Chintankumar Dineshchandra

# Inventory and Warehouse Management System (PostgreSQL + pgAdmin4)

## Objective

Design a SQL backend to manage inventory across multiple warehouses, track product stock levels, monitor suppliers, and handle internal stock transfers efficiently.

---

## Tools Used

- **Database**: PostgreSQL  
- **Client**: pgAdmin4

---

## Schema Design

### 1. `suppliers`
> Stores details of product suppliers.
```sql
-- Table: Suppliers
CREATE TABLE suppliers
(
	supplier_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	contact_info VARCHAR(100)
);
```
### 2. `warehouses`
```sql
-- Table: warehouses
CREATE TABLE warehouses 
(
	warehouse_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	location VARCHAR(100)
);
```
### 3. `products`
```sql
-- Table: products
CREATE TABLE products
(
	prod_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	description TEXT,
	reorder_level INT DEFAULT 10,
	supplier_id INT REFERENCES suppliers(supplier_id)
);
```
### 4. `stock`
```sql
-- Table: stock
CREATE TABLE stock
(
	stock_id SERIAL PRIMARY KEY,
	warehouse_id INT REFERENCES warehouses(warehouse_id),
	prod_id INT REFERENCES products(prod_id),
	quantity INT NOT NULL CHECK(quantity>=0),
	UNIQUE(warehouse_id, prod_id)
);
```

##  Sample Data
Each table is seeded with at least 10 records.
For example: like...
```sql
-- Insert recordes in `suppliers` table
INSERT INTO suppliers (name, contact_info) VALUES
('Alpha Supplies', 'alpha@supplies.com'),
('Beta Traders', 'beta@traders.com'),
------
INSERT INTO warehouses (name, location) VALUES
('Main Warehouse', 'New York'),
('East Hub', 'Boston'),
('West Hub', 'San Francisco'),
('South Depot', 'Miami'),
-------
```
##  Inventory Queries: 
### 3.  Create queries to check stock levels and reorder alerts.
>  This selects specific columns to display:

- `w.name` → alias as `warehouse_name` for readability.

- `p.name` → alias as `product_name`.

- `s.quantity` → current stock level in that warehouse.

- `p.reorder_level` → minimum required quantity for that product.
> Uses the `stock` table as the main source, with alias `s`.
> Inner join between `stock` and `warehouses`:
  - Links each stock record to the warehouse it belongs to.
>  Inner join between `stock` and `products`:
  - Links each stock entry to its associated product.
> Filters only those rows `where`:
  - The current stock (`s.quantity`) is less than the product’s reorder level.

This means the item is running low and may need to be reordered.
```sql
SELECT w.name AS warehouse_name,
	   p.name AS product_name,
	   s.quantity,
	   p.reorder_level
FROM stock s
JOIN warehouses w ON s.warehouse_id = w.warehouse_id
JOIN products p ON s.prod_id = p.prod_id
WHERE s.quantity < p.reorder_level;
```

### 4. Trigger for Low Stock Notification
> Part 1: notify_low_stock() Function
 - Defines a new trigger function named `notify_low_stock`.
 - `RETURNS TRIGGER`: this function is intended to be used with a trigger.
 - `$$...$$`: delimits the function body.
   
 - `BEGIN` : Starts the PL/pgSQL block.
 - `IF`: Checks if the new quantity (after insert or update) is less than the product’s `reorder_level`.
 - `NEW`: a special keyword in triggers representing the new row being inserted or updated.
 - Subquery: fetches the reorder threshold for the product.
   >  Note: Use correct column names (product_id, not prod_id) based on your schema.
 - Triggers a notice message to the PostgreSQL client (visible in pgAdmin query output)
   ```sql
   RAISE NOTICE 'Low stock alert: Product ID % in Warehouse ID % has only % iteam left.',
   NEW.prod_id, NEW.warehouse_id, NEW.quantity;
   ```
 - The `%` placeholders are replaced with values:
  -- `NEW.prod_id` → the product being checked.
  -- `NEW.warehouse_id` → the warehouse it's in.
  -- `NEW.quantity` → the current quantity.
 - `END IF;` : Closes the IF condition.
 - Returns the new row — required for `AFTER INSERT OR UPDATE` triggers.
 - This allows the row to be successfully written/updated in the table.
 - Closes the trigger function.
 - Specifies that it uses the PL/pgSQL language.


```sql
CREATE OR REPLACE FUNCTION notify_low_stock()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.quantity < (SELECT reorder_level FROM products WHERE prod_id = NEW.prod_id)THEN
	RAISE NOTICE 'Low stock alert: Product ID % in Warehouse ID % has only % iteam left.',
	NEW.prod_id, NEW.warehouse_id, NEW.quantity;

	END IF;
	RETURN NEW;	
END;
$$ LANGUAGE plpgsql;
```
> Part 2: `trg_low_stock` Trigger
- Creates the trigger `trg_low_stock`.
- Trigger fires:
   -- `AFTER INSERT OR UPDATE` → after a new stock is added or existing stock is updated.
- `FOR EACH ROW`: executes the function once per row affected.
- `EXECUTE FUNCTION notify_low_stock()`:
   -- Calls the trigger function to check if the stock is below threshold and print a message.
```sql
CREATE TRIGGER trg_low_stock
AFTER INSERT OR UPDATE ON stock
FOR EACH ROW
EXECUTE FUNCTION notify_low_stock();
```
### Insert some data for trigger `trg_low_stock` on
``` sql
INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(3, 4, 33);
```
- Quantity `33` > 6
- No notice will be shown.
- Insert completes silently.

```sql
INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(3, 4, 4); -- display Notice for lower than reorder_level
```
- Quantity 4 < 10
-  Your trigger fires and shows:
```sql
NOTICE:  Low stock alert: Product ID 4 in Warehouse ID 3 has only 4 iteam left.
INSERT 0 1

Query returned successfully in 101 msec.
```
> Note: Make sure the `notify_low_stock()` function is already created and correctly handles the condition for low stock.

### 5. Stored Procedure to Transfer Stock Between Warehouses
> This defines a procedure named transfer_stock.
```sql
CREATE OR REPLACE PROCEDURE transfer_stock(
    from_warehouse INT,
    to_warehouse INT,
    var_prod_id INT,
    qty INT
)

```

-  It accepts 4 input parameters:

   -- `from_warehouse`: ID of the warehouse where stock will be deducted.

   -- `to_warehouse`: ID of the warehouse where stock will be added.

   -- `var_prod_id`: the product ID to transfer.

   -- `qty`: the number of units to transfer.
   
> Language Declaration:
```sql
LANGUAGE plpgsql
```
- Declares that this procedure is written in PL/pgSQL, PostgreSQL's procedural language.

> Begin the procedure block:
```sql
AS $$
BEGIN
```
- Marks the start of the procedure logic using `BEGIN ... END`.
  
> 1. Check available stock in source warehouse
```sql
IF (SELECT quantity 
    FROM stock 
    WHERE warehouse_id = from_warehouse 
      AND prod_id = var_prod_id) < qty THEN
    RAISE EXCEPTION 'Not enough stock to transfer.';
END IF;
```
- This checks if the `from_warehouse` has enough quantity of the given product.
- If available quantity is less than the transfer amount, it raises an exception with the message:
    -- `Not enough stock to transfer.`
- This prevents the transfer from continuing.
  
> 2. Deduct quantity from source warehouse
```sql
UPDATE stock
SET quantity = quantity - qty
WHERE warehouse_id = from_warehouse AND prod_id = var_prod_id;
```
- If stock is sufficient, it updates the stock table:
    -- Reduces quantity in the source warehouse for the given product.
  
> 3. Add quantity to destination warehouse
```sql
INSERT INTO stock (warehouse_id, prod_id, quantity)
VALUES (to_warehouse, var_prod_id, qty)
ON CONFLICT (warehouse_id, prod_id)
DO UPDATE SET quantity = stock.quantity + EXCLUDED.quantity;
```
- Insert the transferred quantity into the destination warehouse.
- f the (`warehouse_id`, `prod_id`) already exists (i.e., product is already stocked there):
   -- It uses `ON CONFLICT` ... `DO UPDATE` to increase the existing quantity.
- `EXCLUDED.quantity` refers to the value you tried to insert (i.e., `qty`).

> End of procedure block:
```sql
END;
$$;

```
- This closes the procedure definition.

### Task 1: Transfer Mouse (prod_id = 3)
```sql
-- Task1: Transfer Mouse (product_id = 3), quantity = 2
-- From: East Hub (warehouse_id = 2)
-- To: Main Warehouse (warehouse_id = 1)

CALL transfer_stock(2, 1, 3, 2);
```
> Step-by-step:
1. Lookup stock in East Hub (warehouse 2):
	```sql
	SELECT quantity FROM stock 
	WHERE warehouse_id = 2 AND prod_id = 3;
	Suppose result = 4
	```
2. 4 ≥ 2 → enough stock to transfer
3. Deduct 2 units from East Hub:
	```sql
	UPDATE stock
	SET quantity = quantity - 2
	WHERE warehouse_id = 2 AND prod_id = 3;
	```
4. Add 2 units to Main Warehouse (insert or update):
	```sql
	INSERT INTO stock (warehouse_id, prod_id, quantity)
	VALUES (1, 3, 2)
	ON CONFLICT (warehouse_id, prod_id)
	DO UPDATE SET quantity = stock.quantity + EXCLUDED.quantity;
	```
>  Result: Mouse moved from East Hub → Main Warehouse

### Task 2: Insert + Update + Transfer Laptop (prod_id = 1)
```sql
-- Insert Laptop (product_id = 1), quantity = 3 to East Hub (warehouse_id = 2)
INSERT INTO stock (warehouse_id, prod_id, quantity)
VALUES (2, 1, 3);
```
- Adds a new stock record:
  -- East Hub now has 3 laptops
```sql
-- Update that record to quantity = 20
UPDATE stock
SET quantity = 20
WHERE warehouse_id = 2 AND prod_id = 1;
```
- Now East Hub has 20 laptops
```sql
-- Transfer 2 laptops from East Hub to Main Warehouse
CALL transfer_stock(2, 1, 1, 2);
```
>  Step-by-step:
1. Check if warehouse 2 has at least 2 of product 1 (Laptop)
  -  Yes (20 ≥ 2)
2. Deduct 2 from East Hub (now 18)
3. Add 2 to Main Warehouse:
  - If no existing row, insert
  - If exists, update


