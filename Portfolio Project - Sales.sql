/*
Таблица sales

year, month, quarter — год, месяц и квартал продажи;
plan — тарифный план (silver, gold, platinum);
price — стоимость одной подписки;
quantity — количество проданных подписок по данному тарифу за месяц;
revenue = price * quantity.

*/


select * from sales limit 10

--Вклад в % каждого тарифа в общую выручку за 2019

select distinct 
year,
plan, 
sum(revenue) over(partition by year, plan) as revenue,
 sum(revenue) over(partition by year) as total,
  round((100*sum(revenue) over(partition by year, plan)/(sum(revenue) over(partition by year)))) as perc 
   from sales
 order by 
  year,
   plan


--Сравнение выручки по кварталам 2019 и 2020 + Динамика QoQ

select distinct 
year, 
quarter,
 sum(revenue) over(partition by quarter) as revenue,
  (select 
   sum(revenue) 
    from sales s1 
  where s1.quarter = s.quarter and s1.year = 2019
  ) as prev,
    round(100*sum(revenue) over(partition by quarter)  
	/
(select 
 sum(revenue) 
  from sales s1 
 where s1.quarter = s.quarter 
  and s1.year = 2019))  
as perc
 from sales s
  where year = 2020


--Cкользящая средняя выручка за 3 месяца для тарифа platinum в 2020 году

select 
year, 
month, 
revenue,
 round(avg(revenue) over(order by year, month rows between 1 preceding and 1 following)) as avg3m 
  from sales
 where plan = 'platinum' 
  and year = 2020  
order by 
 year, 
  month


--Сравнение выручки для тарифа gold по месяцам 2020 года + Динамика MoM

select 
year, 
month,
revenue,
 lag(revenue) over(order by year, month) prev,
  round(100* revenue /(lag(revenue) over(order by year, month))) perc 
from sales 
 where year = 2020 
  and plan = 'gold'
order by 
 year, 
  month


--Рейтинг месяцев 2020 года по количеству продаж по каждому из тарифов

with 
  cte1 as
 (
  select year, month, quantity, rank() over(order by quantity desc) as silv
  from sales 
  where plan = 'silver' and year = 2020
 ), 

   cte2 as
  (
   select year, month, quantity, rank() over(order by quantity  desc) as gol
  from sales 
  where plan = 'gold' and year = 2020
  ), 

    cte3 as
   (
    select year, month,quantity, rank() over(order by quantity  desc) as plat
    from sales 
    where plan = 'platinum' and year = 2020
   ) 

select 
 c1.year, 
  c1.month, 
   c1.silv as silver, 
    c2.gol as gold, 
     c3.plat as platinum  
from cte1 c1
 join cte2  c2
  on c1.year = c2.year and c1.month = c2.month
  join cte3 c3
   on c2.year = c3.year and c2.month = c3.month
order by 
 c1.year, 
  c1.month







