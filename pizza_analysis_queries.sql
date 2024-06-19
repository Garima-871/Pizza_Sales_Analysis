use pizza_sales_analysis;
select * from order_details;
select * from orders;
select * from pizza_types;
select * from pizzas;

# query solutions of business questions:
-- get total number of orders placed
select count( distinct order_id) as 'total orders' from orders;

-- calculate total revenue generated from pizza sales
select order_details.pizza_id,order_details.quantity,pizzas.price from order_details
join pizzas on order_details.pizza_id = pizzas.pizza_id;

select cast(sum(order_details.quantity * pizzas.price) as decimal(10,2)) as 'Total revenue'
from order_details
join pizzas on order_details.pizza_id = pizzas.pizza_id;

-- identify highest price pizza
select pizza_types.name as 'Pizza name',cast(pizzas.price as decimal(10,2)) as 'Price' from pizzas 
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by price desc;
-- alternate solution using window/func
with cte as(
select pizza_types.name as 'Pizza name', cast((pizzas.price) as decimal(10,2)) as 'Price',
rank() over w as rank_num from pizza_types join pizzas on 
pizza_types.pizza_type_id = pizzas.pizza_type_id 
window w as (order by price desc))

select * from cte c where rank_num= 1 ;


-- identify most common pizza size ordered
select pizzas.size,count(distinct order_id) as 'No of Orders', sum(quantity) as 'Total Quantity ordered'
from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id
group by pizzas.size
order by 'No of Orders' desc;

-- List the top 5 most ordered pizza types along with their quantities.
select pizza_types.name, count(distinct order_id) as no_of_unique_orders,sum(quantity) as total_quantity_ordered
from pizzas 
join order_details on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by total_quantity_ordered desc;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pizza_types.category, count(distinct order_id) as no_of_unique_orders,sum(quantity) as total_quantity_ordered
from pizzas 
join order_details on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category
order by total_quantity_ordered desc;

-- Determine the distribution of orders by hour of the day.
select hour(time) as hour_of_the_day, count(distinct order_id) as no_of_orders
from orders group by hour_of_the_day
order by no_of_orders desc;

-- find the category wise distribution of the pizzas
select category, count(distinct pizza_type_id) as no_of_pizzas
from pizza_types
group by category
order by no_of_pizzas;

-- Calculate the avg number of pizzas ordered per day.
select avg(total_pizza_ordered_that_day) as avg_pizzas_ordered_per_day from 
(select orders.date as order_date, sum(order_details.quantity) as total_pizza_ordered_that_day
from orders join order_details on orders.order_id = order_details.order_id
group by orders.date
) 
as pizzas_ordered;

-- determine the top 3 most ordered pizza types based on revenue
select pizza_types.name as pizza_name,sum(order_details.quantity * pizzas.price) as revenue_from_pizza
from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id 
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_name order by revenue_from_pizza desc
limit 3;

-- calculate the percentage contribution of each pizza type to total revenues

select pizza_types.category, concat(cast((sum(order_details.quantity * pizzas.price) /  
(select sum(order_details.quantity * pizzas.price) from
order_details join pizzas on order_details.pizza_id = pizzas.pizza_id
)   -- total revenue from this subquery
)
* 100 as decimal(10,2)),'%') as 'Revenue contribution from pizza'
from order_details
join pizzas on order_details.pizza_id = pizzas.pizza_id 
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category;

-- % revenue contribution from each pizza by pizza name

select pizza_types.name, concat(cast(sum(order_details.quantity * pizzas.price) /
(select sum(order_details.quantity * pizzas.price) 
from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id
) * 100 as decimal(10,2)),'%') as revenue_contribution_from_pizza
from 
order_details join pizzas on order_details.pizza_id = pizzas.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by revenue_contribution_from_pizza desc;

-- Analyse cummulative revenue generated over time
with cte as(
select orders.date as order_date , cast(sum(quantity * price) as decimal(10,2)) as revenue_by_date
from order_details 
join orders on order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = order_details.pizza_id 
group by orders.date

)
 select order_date , revenue_by_date, sum(revenue_by_date) over (order by order_date) as cumulative_sum
 from cte
 group by order_date,revenue_by_date; 

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as ( 
select pizza_types.category, pizza_types.name,cast(sum(order_details.quantity * pizzas.price)
as decimal(10,2)) as Revenue
from order_details 
join pizzas on order_details.pizza_id = pizzas.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category,pizza_types.name
),
cte1 as (
select category,name,Revenue ,
rank() over(partition by category order by Revenue desc) as rank_num from cte
)
select category,name,Revenue from 
cte1 where rank_num between 1 and 3
order by category,name,Revenue;



