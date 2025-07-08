/*Project_4. Inventory and Warehouse Management System Objective:
Design a SQL backend for warehouse inventory tracking.
Tools: pgAdmin4
Mini Guide:
1.Model schema for Products, Warehouses, Suppliers, Stock.
2.Insert sample inventory records.
3.Create queries to check stock levels and reorder alerts.
4.Write triggers for low-stock notification.
5.Create stored procedure to transfer stock.
6.Document schema and queries.
Deliverables:
SQL schema, triggers, procedures, inventory queries.
*/

-- Table: Suppliers
CREATE TABLE suppliers
(
	supplier_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	contact_info VARCHAR(100)
);

-- Table: warehouses
CREATE TABLE warehouses 
(
	warehouse_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	location VARCHAR(100)
);

-- Table: products
CREATE TABLE products
(
	prod_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	description TEXT,
	reorder_level INT DEFAULT 10,
	supplier_id INT REFERENCES suppliers(supplier_id)
);

-- Table: stock
CREATE TABLE stock
(
	stock_id SERIAL PRIMARY KEY,
	warehouse_id INT REFERENCES warehouses(warehouse_id),
	prod_id INT REFERENCES products(prod_id),
	quantity INT NOT NULL CHECK(quantity>=0),
	UNIQUE(warehouse_id, prod_id)
);