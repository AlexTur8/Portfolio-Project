/*
Таблица employee

id_emp - id работника
empname - имя работника

Таблица emp_prem

id_emp - id работника
month - дата (год, месяц, день)
premium - премия 
*/


--Вывести всех сотрудников, имеющих максимальную премию в каждом месяце

with 
pr as 
(
select 
  e.id_emp, 
  empname, 
  date_part('month', month) as month,  
  sum(premium) as premium
  from emp_prem p
left join employee e 
on p.id_emp = e.id_emp 
group by e.id_emp, empname, month
),
rnf as 
(
select pr.*,
dense_rank() over(partition by month order by premium desc) as rn
from pr
)
select * 
from rnf
where rn=1



-- Тем сотрудникам, у которых в данном месяце максимальна, удвоить ее, если премия максимальна у нескольких сотрудников, удвоение не производить

with 
pr as 
(
select 
  e.id_emp, 
  empname, 
  date_part('month', month) as month,  
  sum(premium) as premium
  from emp_prem p
left join employee e 
on p.id_emp = e.id_emp 
group by e.id_emp, empname, month
),
rnf as 
(
select pr.*,
dense_rank() over(partition by month order by premium desc) as rn
from pr
),
td as
(
select rnf.*,
count(id_emp) over(partition by month order by premium desc) as count_rn
from rnf
where rn=1
)
select 
id_emp, 
empname, 
month, 
premium, 
case when count_rn = 1 then premium*2 else premium end 
as ДвойнаяПремия
from td


/*
Таблица transaction

id_card - id карты
date_transac - дата транзакции (год, месяц, день)
cash - сумма транзакций

Таблица card

id_card - id карты
date_activ - дата активации карты (год, месяц, день)
limit - лимит по карте
*/


-- Вывести карты, у которых была хотя бы одна транзакция в течении 30 дней с момента активации карты

with 
sd as 
(
select 
c.id_card, 
date_transac, 
cash, 
date_activ, 
c.limit, 
date_activ + integer '30' as date_plus_30d
from transaction t 
 left join card c 
  on c.id_card = t.id_card
  )
    select id_card 
     from sd
     where date_transac between date_activ and date_plus_30d
     group by id_card
     
     

 --Вывести карты, у которых сумма транзакций составляет более 80%
     
 with sd as
(
select 
t.id_card, 
sum(cash) as sum_trans,
c.limit,
 sum(cash)*100 / c.limit as perc
from transaction t 
 left join card c 
   on c.id_card = t.id_card
group by t.id_card, c.limit
order by t.id_card
)
select id_card, sum_trans, sd.limit 
  from sd
   where perc > 80