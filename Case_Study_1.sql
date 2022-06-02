CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


--############################################


SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

--############################################


--1.What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id, SUM(m.price) total_amount
FROM sales s join menu m on s.product_id = m.product_id
GROUP BY s.customer_id
order by s.customer_id

--2.How many days has each customer visited the restaurant?

SELECT
	customer_id,
	count(distinct order_date) #days
FROM sales
group by customer_id;


--3.What was the first item from the menu purchased by each customer?

WITH CTE1 AS(
SELECT
	customer_id,
	order_date,
	product_name,
	ROW_NUMBER() OVER(partition by customer_id order by order_date) rn
FROM sales s JOIN menu m ON s.product_id = m.product_id
)
SELECT
	customer_id,
	product_name
FROM CTE1
WHERE rn = 1


--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	top(1)
	product_name,
	count(s.product_id) as purchased
FROM
	sales s,
	menu m
WHERE m.product_id = s.product_id
GROUP BY product_name
ORDER BY purchased DESC;


--5.Which item was the most popular for each customer?
WITH C1 AS(
SELECT
	customer_id,
	product_name,
	count(product_name) count_of_items,
	DENSE_RANK() OVER(partition by customer_id ORDER BY count(product_name) DESC) rn
FROM sales s join menu m on s.product_id = m.product_id
group by customer_id, product_name
)
SELECT
	customer_id,
	product_name,
	count_of_items
FROM C1
WHERE rn = 1


--6.Which item was purchased first by the customer after they became a member?
WITH C1 AS(
SELECT
	s.customer_id,
	m.join_date,
	s.order_date,
	product_id,
	DENSE_RANK() OVER(partition by s.customer_id order by product_id) rn
FROM sales s join members m on s.customer_id = m.customer_id
where order_date >= join_date
)
SELECT
	customer_id,
	join_date,
	order_date,
	m.product_name
FROM C1 c join menu m ON c.product_id = m.product_id
WHERE rn = 1


--7.Which item was purchased just before the customer became a member?
WITH C1 AS(
SELECT
	s.customer_id,
	m.join_date,
	s.order_date,
	product_id,
	DENSE_RANK() OVER(partition by s.customer_id order by product_id) rn
FROM sales s join members m on s.customer_id = m.customer_id
where order_date < join_date
)
SELECT
	customer_id,
	join_date,
	order_date,
	m.product_name
FROM C1 c join menu m ON c.product_id = m.product_id
WHERE rn = 1


--8.What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
	COUNT(s.product_id) Total_items,
	SUM(m.price) amount_spent
FROM sales s join menu m on s.product_id = m.product_id
join members ms on s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
group by s.customer_id;


--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH c1 as(
SELECT
	customer_id,
	m.product_name,
	SUM(price) amount,
	case when m.product_name = 'sushi' then SUM(price) * 20 else 0 end sushi,
	case when m.product_name <> 'sushi' then SUM(price) * 10 else 0 end others
FROM sales s join menu m on s.product_id = m.product_id
group by customer_id, m.product_name
),
c2 AS(
	SELECT
		customer_id,
		SUM(sushi) + SUM(others) amount
	FROM c1
	group by customer_id
)
select * from c2;




--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS(
	SELECT
		*,
		DATEADD(DAY, 6, join_date) First_Week,
		EOMONTH(join_date) EndOMONTH
	FROM members m
)
SELECT
	s.customer_id,
	SUM(
		case
			when s.order_date between join_date and First_Week then price * 20
			when product_name = 'sushi' then price * 20
			else price * 10
		end
	) total_amount
FROM dates d join sales s on d.customer_id = s.customer_id
join menu m on s.product_id = m.product_id
where order_date <= EndOMONTH
group by s.customer_id;




--Bonus Questions--
--Question 1
--The following questions are related creating basic data tables that Danny and his team can use to quickly
--derive insights without needing to join the underlying tables using SQL.
SELECT
    s.customer_id,
    s.order_date,
	menu.product_name,
	menu.price,
    CASE
        WHEN s.order_date >= m.join_date THEN 'Y' ELSE 'N'
    END member
FROM sales s left join members m on s.customer_id = m.customer_id
join menu on s.product_id = menu.product_id




--Question 2
--Danny also requires further information about the ranking of customer products, but he purposely does not need
--the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH all_tables AS(
	SELECT
		s.customer_id,
		s.order_date,
		menu.product_name,
		menu.price,
		CASE
			WHEN s.order_date >= m.join_date THEN 'Y' ELSE 'N'
		END member
	FROM sales s left join members m on s.customer_id = m.customer_id
	join menu on s.product_id = menu.product_id
)
SELECT
	*,
	CASE
		WHEN member = 'Y' THEN DENSE_RANK() OVER(partition by customer_id, member order by order_date) 
	END ranking
FROM all_tables



--############################################
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;
--############################################

