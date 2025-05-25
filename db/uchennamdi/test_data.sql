-- Insert fashion products
INSERT INTO FashionProducts (product_name, description, category, price, stock)
VALUES
('Classic T-Shirt', 'Premium cotton t-shirt', 'Clothing', 29.99, 100),
('Designer Jeans', 'High-quality designer jeans', 'Clothing', 89.99, 50),
('Leather Bag', 'Handcrafted leather bag', 'Accessories', 129.99, 25);

-- Get product IDs
SET @prod1_id = LAST_INSERT_ID();
SET @prod2_id = @prod1_id + 1;
SET @prod3_id = @prod1_id + 2;

-- Insert customer details
INSERT INTO CustomerDetails (user_id, bust_cm, waist_cm, hip_cm, height_cm, inseam_cm, sleeve_length_cm, color_preferences, style_preferences)
VALUES
(1, 92.5, 76.2, 97.8, 175.3, 81.2, 63.5, 'blue,green,black', 'casual,minimalist'),
(2, 88.9, 72.4, 94.0, 168.2, 78.7, 61.0, 'red,purple,black', 'bohemian,vintage'),
(3, 95.3, 79.5, 101.6, 180.3, 83.8, 65.2, 'earth tones,white', 'professional,classic');

-- Insert fashion orders
INSERT INTO FashionOrders (user_id, order_date, total_amount, status, shipping_address, payment_method)
VALUES
(1, DATE_SUB(NOW(), INTERVAL 20 DAY), 59.98, 'delivered', '123 Main St, London, UK', 'credit_card'),
(2, DATE_SUB(NOW(), INTERVAL 10 DAY), 219.97, 'shipped', '456 High St, Berlin, Germany', 'paypal'),
(3, DATE_SUB(NOW(), INTERVAL 5 DAY), 129.99, 'processing', '789 Rue de Paris, Paris, France', 'credit_card');

-- Get order IDs
SET @order1_id = LAST_INSERT_ID();
SET @order2_id = @order1_id + 1;
SET @order3_id = @order1_id + 2;

-- Insert order items
INSERT INTO OrderItems (order_id, product_id, quantity, price_per_unit)
VALUES
(@order1_id, @prod1_id, 2, 29.99),
(@order2_id, @prod1_id, 1, 29.99),
(@order2_id, @prod2_id, 1, 89.99),
(@order2_id, @prod3_id, 1, 129.99),
(@order3_id, @prod3_id, 1, 129.99);

-- Insert fashion projects
INSERT INTO FashionProjects (user_id, title, description, type, tier_level, start_date, status)
VALUES
(1, 'Custom T-Shirt Design', 'Creating custom-designed t-shirts', 'project', 'community', NOW(), 'planning'),
(2, 'Fashion Catalog', 'Development of seasonal fashion catalog', 'project', 'partnership', NOW(), 'active'),
(3, 'Retail Integration', 'Integrating systems with retail partners', 'operation', 'partnership', NOW(), 'active');
