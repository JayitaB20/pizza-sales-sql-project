CREATE TABLE pizzas (
    pizza_id      VARCHAR(50)    PRIMARY KEY,
    pizza_type_id VARCHAR(50)    NOT NULL,
    size          VARCHAR(3)     NOT NULL,
    price         NUMERIC(5, 2)  NOT NULL
);

SELECT * FROM pizzas

CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50)   PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    category      VARCHAR(20)   NOT NULL,
    ingredients   TEXT          NOT NULL
);

SELECT * FROM pizza_types;

ALTER TABLE PIZZAS
ADD CONSTRAINT FK_PIZZA_TYPE FOREIGN KEY (PIZZA_TYPE_ID) REFERENCES PIZZA_TYPES (PIZZA_TYPE_ID);

CREATE TABLE orders (
    order_id  INTEGER  PRIMARY KEY,
    date      DATE     NOT NULL,
    time      TIME     NOT NULL
);

SELECT * FROM orders;

CREATE TABLE order_details (
    order_details_id  INTEGER      PRIMARY KEY,
    order_id          INTEGER      NOT NULL REFERENCES orders(order_id),
    pizza_id          VARCHAR(50)  NOT NULL REFERENCES pizzas(pizza_id),
    quantity          SMALLINT     NOT NULL CHECK (quantity > 0)
);

SELECT * FROM order_details;

-- 1) Retrieve the total number of orders placed

SELECT COUNT(order_id) AS Total_Orders
FROM orders;

-- 2) Calculate the total revenue generated from pizza sales

SELECT
	ROUND(SUM(OD.QUANTITY * P.PRICE)::NUMERIC, 2) AS TOTAL_REVENUE
FROM
	ORDER_DETAILS OD
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID;

-- 3) Identify the highest-priced pizza

SELECT
	P.PIZZA_TYPE_ID,
	PT.NAME,
	P.PRICE
FROM
	PIZZAS P
	JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
ORDER BY
	P.PRICE DESC
LIMIT
	1;

-- 4) Identify the most common pizza size ordered

SELECT
	P.SIZE,
	COUNT(OD.ORDER_DETAILS_ID) AS ORDER_COUNT
FROM
	PIZZAS P
	JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	P.SIZE
ORDER BY
	ORDER_COUNT DESC;

-- 5) List the top 5 most ordered pizza types along with their quantities

SELECT
	PT.NAME,
	SUM(OD.QUANTITY) AS ORDER_QUANTITY
FROM
	PIZZA_TYPES PT
	JOIN PIZZAS P ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	PT.NAME
ORDER BY
	ORDER_QUANTITY DESC
LIMIT
	5;

-- 6) Join the necessary tables to find the total quantity of each pizza category ordered

SELECT
	PT.CATEGORY,
	SUM(OD.QUANTITY) AS ORDER_QUANTITY
FROM
	PIZZA_TYPES PT
	JOIN PIZZAS P ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	PT.CATEGORY
ORDER BY
	ORDER_QUANTITY DESC;

-- 7) Determine the distribution of orders by hour of the day

SELECT 
    EXTRACT(HOUR FROM time) AS hour,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY hour
ORDER BY hour;

-- 8) Join relevant tables to find the category-wise distribution of pizzas

SELECT
	CATEGORY,
	COUNT(NAME)
FROM
	PIZZA_TYPES
GROUP BY
	CATEGORY;

-- 9) Group the orders by date and calculate the average number of pizzas ordered per day
SELECT
	ROUND(AVG(QUANTITY_ORDERED), 2) AS AVERAGE_PIZZAS_ORDERED_PER_DAY
FROM
	(
		SELECT
			O.DATE,
			SUM(OD.QUANTITY) AS QUANTITY_ORDERED
		FROM
			ORDERS O
			JOIN ORDER_DETAILS OD ON O.ORDER_ID = OD.ORDER_ID
		GROUP BY
			DATE
	) AS DAILY_ORDERS;

-- 10) Determine the top 3 most ordered pizza types based on revenue

SELECT
	PT.NAME,
	ROUND(SUM(OD.QUANTITY * P.PRICE), 2) AS REVENUE
FROM
	PIZZA_TYPES PT
	JOIN PIZZAS P ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
	JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	PT.NAME
ORDER BY
	REVENUE DESC
LIMIT
	3;

-- 11) Calculate the percentage contribution of each pizza type to total revenue

SELECT
	PT.CATEGORY,
	ROUND(
		SUM(OD.QUANTITY * P.PRICE) * 100.0 / SUM(SUM(OD.QUANTITY * P.PRICE)) OVER (),
		2
	) AS PCT_CONTRIBUTION
FROM
	ORDER_DETAILS OD
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID
	JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
GROUP BY
	PT.CATEGORY
ORDER BY
	PCT_CONTRIBUTION DESC;

-- 12) Analyze the cumulative revenue generated over time

SELECT
	O.DATE,
	ROUND(
		SUM(SUM(OD.QUANTITY * P.PRICE)) OVER (
			ORDER BY
				O.DATE
		)::NUMERIC,
		2
	) AS CUMULATIVE_REVENUE
FROM
	ORDERS O
	JOIN ORDER_DETAILS OD ON O.ORDER_ID = OD.ORDER_ID
	JOIN PIZZAS P ON OD.PIZZA_ID = P.PIZZA_ID
GROUP BY
	O.DATE;

-- 13) Determine the top 3 most ordered pizza types based on revenue for each pizza category

SELECT
	CATEGORY,
	NAME,
	REVENUE
FROM
	(
		SELECT
			PT.CATEGORY,
			PT.NAME,
			ROUND(SUM(OD.QUANTITY * P.PRICE), 2) AS REVENUE,
			ROW_NUMBER() OVER (
				PARTITION BY
					PT.CATEGORY
				ORDER BY
					SUM(OD.QUANTITY * P.PRICE) DESC
			) AS RNK
		FROM
			PIZZA_TYPES PT
			JOIN PIZZAS P ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
			JOIN ORDER_DETAILS OD ON P.PIZZA_ID = OD.PIZZA_ID
		GROUP BY
			PT.NAME,
			PT.CATEGORY
	) AS A
WHERE
	RNK <= 3;

