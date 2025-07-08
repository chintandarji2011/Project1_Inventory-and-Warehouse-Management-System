-- Insert recordes in `suppliers` table
INSERT INTO suppliers (name, contact_info) VALUES
('Alpha Supplies', 'alpha@supplies.com'),
('Beta Traders', 'beta@traders.com'),
('Gamma Goods', 'gamma@goods.com'),
('Delta Distributors', 'delta@distributors.com'),
('Epsilon Exports', 'epsilon@exports.com'),
('Zeta Zone', 'zeta@zone.com'),
('Eta Enterprises', 'eta@enterprises.com'),
('Theta Traders', 'theta@traders.com'),
('Iota Imports', 'iota@imports.com'),
('Kappa Korea Co.', 'kappa@korea.com');

-- Insert recordes in `warehouses` table
INSERT INTO warehouses (name, location) VALUES
('Main Warehouse', 'New York'),
('East Hub', 'Boston'),
('West Hub', 'San Francisco'),
('South Depot', 'Miami'),
('North Storage', 'Chicago'),
('Central Hub', 'Dallas'),
('Mountain Store', 'Denver'),
('Desert Storage', 'Phoenix'),
('Harbor Warehouse', 'Los Angeles'),
('River Depot', 'Cincinnati');

-- Insert recordes in `products` table
INSERT INTO products (name, description, reorder_level, supplier_id) VALUES
('Laptop', '15-inch laptop with SSD', 5, 1),
('Keyboard', 'Mechanical backlit keyboard', 10, 2),
('Mouse', 'Wireless optical mouse', 8, 3),
('Monitor', '27-inch LED monitor', 6, 4),
('Printer', 'All-in-one inkjet printer', 4, 5),
('Scanner', 'High-speed document scanner', 7, 6),
('Tablet', '10-inch Android tablet', 5, 7),
('Router', 'Wi-Fi 6 dual-band router', 9, 8),
('Speaker', 'Bluetooth portable speaker', 6, 9),
('Webcam', 'HD webcam with microphone', 3, 10);

-- Insert recordes in `stock`  table
INSERT INTO stock (warehouse_id, prod_id, quantity) VALUES
(1, 1, 12),   -- Main Warehouse - Laptop
(1, 2, 7),    -- Main Warehouse - Keyboard
(2, 3, 15),   -- East Hub - Mouse
(2, 4, 4),    -- East Hub - Monitor (Low stock)
(3, 5, 10),   -- West Hub - Printer
(4, 6, 3),    -- South Depot - Scanner (Low stock)
(5, 7, 20),   -- North Storage - Tablet
(6, 8, 6),    -- Central Hub - Router
(7, 9, 8),    -- Mountain Store - Speaker
(8, 10, 2);   -- Desert Storage - Webcam (Low stock)


SELECT * FROM suppliers;
SELECT * FROM warehouses;
SELECT * FROM products;
SELECT * FROM stock;
