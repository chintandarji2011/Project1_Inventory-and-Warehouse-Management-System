-- 3.Create queries to check stock levels and reorder alerts.
---  View current stock levels:
SELECT w.name AS warehouse_name,
	   p.name AS product_name,
	   s.quantity
FROM stock s
JOIN warehouses w ON s.warehouse_id = w.warehouse_id
JOIN products p ON s.prod_id = p.prod_id
ORDER BY s.warehouse_id;

--- Products below reorder level:
SELECT w.name AS warehouse_name,
	   p.name AS product_name,
	   s.quantity,
	   p.reorder_level
FROM stock s
JOIN warehouses w ON s.warehouse_id = w.warehouse_id
JOIN products p ON s.prod_id = p.prod_id
WHERE s.quantity < p.reorder_level;

-- 4. Trigger for Low Stock Notification
--- Create a function: `notify_low_stock`
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

--- create a trigger:`trg_low_stock`
CREATE TRIGGER trg_low_stock
AFTER INSERT OR UPDATE ON stock
FOR EACH ROW
EXECUTE FUNCTION notify_low_stock();

---- Insert some data for trigger `trg_low_stock` on

INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(3, 4, 33);
INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(3, 4, 4); -- display Notice for lower than reorder_level


---- Reset previous status
DELETE FROM stock WHERE warehouse_id = 3 AND prod_id = 4;

-- 5. Stored Procedure to Transfer Stock Between Warehouses
CREATE OR REPLACE PROCEDURE transfer_stock
(
	from_warehouse INT,
	to_warehouse INT,
	var_prod_id INT,
	qty INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	-- check available of stock
	IF(SELECT quantity FROM stock WHERE warehouse_id = from_warehouse AND prod_id = var_prod_id) < qty THEN
		RAISE EXCEPTION 'Not enough stock to transfer.';
	END IF;

	-- Deduct from source warehouse 
	UPDATE stock
	SET quantity = quantity - qty
	WHERE warehouse_id = from_warehouse AND prod_id = var_prod_id;

	-- Add to destination warehouse
	INSERT INTO stock (warehouse_id, prod_id, quantity)
	VALUES (to_warehouse, var_prod_id, qty)
	ON CONFLICT (warehouse_id, prod_id)
	DO UPDATE SET quantity = stock.quantity + EXCLUDED.quantity;
END;
$$;

-- Task1: Query transfer `Mouse`(3) `quantity=4` from `East Hub`(2) to warehouse `Main warehouse`(1)
CALL transfer_stock(2,1,3,2);
-- Task:2 Insert some `laptop`(1) `quantity = 3` and update (quantity= 20) in `EastHub`(2) warehouse and transfer `qty = 2` 
-- by `transfer_stock` sp from `East Hub`(2) to `Main Warehouse`(1)
INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(2, 1, 3);
UPDATE stock SET quantity = 20 WHERE warehouse_id= 2 and prod_id = 1;
CALL transfer_stock(2, 1, 1, 2);

