--Tao database ProjectBI 
CREATE DATABASE ProjectBI

ALTER TABLE dbo.order_items_dataset
ALTER COLUMN price MONEY

ALTER TABLE dbo.order_items_dataset
ALTER COLUMN freight_value MONEY
 
ALTER TABLE dbo.order_payments_dataset
ALTER COLUMN payment_value MONEY

ALTER TABLE dbo.order_items_dataset
ADD CONSTRAINT order_items_dataset_pk PRIMARY KEY (order_id, product_id,order_item_id);

EXEC sp_rename '[dbo].[product_category_name_translation].column2', 'Product_category_name_english', 'COLUMN';

--Doanh thu theo order
SELECT 
	order_id, 
	product_id, 
	COUNT(order_item_id) AS quantity, 
	price, 
	(COUNT(order_item_id)*price) AS revenue, 
	freight_value
FROM dbo.order_items_dataset
GROUP BY 
	order_id, 
	product_id, price, 
	freight_value
ORDER BY quantity DESC

--Doanh thu theo vung
SELECT
	c.customer_city,
	c.customer_state,
	SUM(r.revenue) AS revenue
FROM dbo.customers_dataset c
JOIN dbo.orders_dataset o
	ON o.customer_id = c.customer_id
JOIN [dbo].[order_items_dataset_revenue] r
	ON r.order_id = o.order_id
GROUP BY c.customer_city,c.customer_state
ORDER BY revenue DESC;

----Doanh thu theo vung
WITH r AS (
	SELECT 
	order_id, 
	product_id, 
	COUNT(order_item_id) AS quantity, 
	price, 
	(COUNT(order_item_id)*price) AS revenue, 
	freight_value
FROM dbo.order_items_dataset
GROUP BY 
	order_id, 
	product_id, price, 
	freight_value
)
SELECT
	c.customer_city,
	c.customer_state,
	SUM(r.revenue) AS revenue
FROM dbo.customers_dataset c
JOIN dbo.orders_dataset o
	ON o.customer_id = c.customer_id
JOIN r 
	ON r.order_id = o.order_id
GROUP BY c.customer_city,c.customer_state
ORDER BY revenue DESC

SELECT 
	customer_city,
	customer_state
FROM dbo.customers_dataset
GROUP BY customer_city,customer_state
ORDER BY customer_city ASC

-- map dashboard
SELECT 
	c.customer_state, 
	b.Latitude, 
	b.longitude, 
	SUM(r.revenue) AS revenue
FROM dbo.customers_dataset c
	LEFT JOIN [dbo].[Brazil_state] b 
	ON b.UF = c.customer_state
	LEFT JOIN dbo.orders_dataset o 
	ON o.customer_id = c.customer_id
	LEFT JOIN [dbo].[order_items_dataset_revenue] r 
	ON r.order_id = o.order_id
GROUP BY c.customer_state, b.Latitude, b.longitude


--tinh hinh kinh doanh cua san pham
SELECT 
	o.product_id,
	COUNT(o.order_item_id) AS quantity,
	p.product_category_name,
	t.product_category_name_english
FROM dbo.order_items_dataset o
	JOIN dbo.products_dataset p
	ON p.product_id = o.product_id
	JOIN dbo.product_category_name_translation t
	ON t.product_category_name =p.product_category_name
GROUP BY o.product_id, p.product_category_name, t.product_category_name_english
ORDER BY quantity DESC

--san luong san pham ban duoc theo nganh hang
SELECT 
	p.product_category_name,
	t.product_category_name_english,
	COUNT(o.order_item_id) AS quantity
FROM dbo.order_items_dataset o
	JOIN dbo.products_dataset p
	ON p.product_id = o.product_id
	JOIN dbo.product_category_name_translation t
	ON t.product_category_name=p.product_category_name
GROUP BY p.product_category_name, t.product_category_name_english
ORDER BY quantity DESC

--tinh hinh doanh so theo nganh hang
SELECT
	t.product_category_name_english,
	SUM(r.revenue) AS revenue
FROM dbo.order_items_dataset_revenue r
	JOIN dbo.products_dataset p
	ON p.product_id = r.product_id
	JOIN dbo.product_category_name_translation t
	ON t.product_category_name= p.product_category_name
GROUP BY t.product_category_name_english
ORDER BY revenue DESC


-- diem hai long cua KH
SELECT 
	od.order_id, 
	od.customer_id, 
	od.order_status, 
	ord.review_score
FROM dbo.orders_dataset od
	INNER JOIN dbo.order_reviews_dataset ord
	ON ord.order_id = od.order_id

SELECT AVG(review_score) AS avg_score
FROM dbo.order_reviews_dataset

--so lan mua hang lap lai cua KH

SELECT 
	customer_unique_id, 
	COUNT(DISTINCT(customer_id)) num_order
FROM dbo.customers_dataset
GROUP BY customer_unique_id
ORDER BY num_order DESC

--tinh hinh van hanh don, thoi gian ship den khach hang
SELECT 
	order_id,
	order_status,
	order_approved_at,
	order_delivered_customer_date,
	DATEDIFF(DAY,order_approved_at,order_delivered_customer_date) shipping_time
FROM dbo.orders_dataset
WHERE order_delivered_customer_date IS NOT NULL

WITH ship AS (
	SELECT 
		order_id,
		order_status,
		order_approved_at,
		order_delivered_customer_date,
		DATEDIFF(DAY,order_approved_at,order_delivered_customer_date) shipping_time
	FROM dbo.orders_dataset
	WHERE order_delivered_customer_date IS NOT NULL)
SELECT AVG(ship.shipping_time)
FROM ship