-- ======================--CASE STUDY QUESTIONS--===============================

USE Challenge;

-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(price) as total_sales
from sales as s
join menu as m
on s.product_id = m.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date)) as visit_count
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with ordered_sales_cte as
(
select s.customer_id, s.order_date, m.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date) as rank_num
from sales as s
join menu as m
using(product_id)
)

select customer_id, order_date, product_name, rank_num
from ordered_sales_cte
where rank_num = 1
group by  customer_id, order_date, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(s.product_id) as most_purchased
from sales as s
join menu as m
using(product_id)
group by m.product_name
order by most_purchased desc
limit 1;

-- 5. Which item was the most popular for each customer?

with fav_item_cte as
(
select s.customer_id, m.product_name, count(s.product_id) as order_count,
dense_rank() over(partition by s.customer_id order by count(s.product_id) desc) as rank_num
from sales as s
join menu as m
using(product_id)
group by s.customer_id, m.product_name
)

select customer_id, product_name, order_count
from fav_item_cte
where rank_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with members_sales_cte as
(
select s.customer_id, m.join_date, s.order_date, s.product_id,
dense_rank() over(partition by s.customer_id order by s.order_date) as rank_num
from sales as s
join members as m
using(customer_id)
where s.order_date > m.join_date
)

select * 
from members_sales_cte
where rank_num = 1;
-- 7. Which item was purchased just before the customer became a member?

with prior_member_purchased_cte as
(
select s.customer_id, m.join_date, s.order_date, s.product_id,
dense_rank() over(partition by s.customer_id order by s.order_date desc) as rank_num
from sales as s
join members as m
using(customer_id)
where s.order_date < m.join_date
)

select * 
from prior_member_purchased_cte
where rank_num = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(distinct s.product_id) as total_items, sum(mn.price) as total_sales
from sales as s
join menu as mn
using(product_id)
join members as mb
using(customer_id)
where s.order_date < mb.join_date
group by s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a x2 points multiplier — how many points would each customer have?

WITH price_points_cte AS
(
   SELECT *, 
      CASE
         WHEN product_id = 1 THEN price * 10 * 2
         ELSE price * 10
      END AS points
   FROM menu
)

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points_cte AS p
JOIN sales AS s
   ON p.product_id = s.product_id
GROUP BY s.customer_id;

with price_points_cte as
(
select *,
(case
when product_id = 1 then price * 10 * 2
else price * 10
end) as points
from menu
)

select s.customer_id, sum(p.points) as total_points
from price_points_cte as p
join sales as s using(product_id)
group by s.customer_id;

-- ======================--BONUS QUESTIONS--===============================

-- Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

select s.customer_id, s.order_date, m.product_name, m.price,
case
when mb.join_date > s.order_date then 'N'
else 'Y'
end as member
from sales as s
left join menu as m using(product_id)
left join members as mb using(customer_id);

-- Rank All the Things

with summary_cte as
(
select s.customer_id, s.order_date, m.product_name, m.price,
case
when mb.join_date > s.order_date then 'N'
else 'Y'
end as member
from sales as s
left join menu as m using(product_id)
left join members as mb using(customer_id)
)

select *, 
case
when member = 'N' then NULL
else dense_rank() over(partition by customer_id, member order by order_date) end as ranking
from summary_cte;