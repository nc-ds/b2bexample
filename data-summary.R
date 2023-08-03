
library(lubridate)
library(sqldf)


getwd()
setwd('jiffyshirts')

custs <- read.csv('customers.csv')
items <- read.csv('line_items.csv')
orders <- read.csv('orders.csv')


summary(custs)
summary(items)
summary(orders)

is.data.frame(orders)

# 1. How many orders were completed in 2018? (Note: We operate in US/Eastern time zone)

# date stored in UTC - convert end points of 2018 to US/Eastern time
# set to date stored as UTC; then convert to desired zone 
orders$order_dt = as.POSIXct(orders$order_timestamp,tz= "UTC")
attr(orders$order_dt, "tzone") <- "US/Eastern"
tz(orders$order_dt)

orders$year <- year(orders$order_dt)
orders$month <- month(orders$order_dt)
table(orders$year, orders$month)

sqldf( "select * from orders limit 100 ")

sqldf( "select count(distinct order_id) as n_ord from orders where year = 2018 ")

# There were 9228 orders in 2018

# 2. How many orders were completed in 2018 containing at least 10 units?

sqldf( "select * from items limit 100 ")

ord18 = sqldf("select distinct order_id from orders where year = 2018")

sqldf(" select  count( distinct order_id ) from (
      select order_id,  sum(quantity) as n_items from items where order_id in (select order_id from ord18 )
       group by order_id 
      ) where n_items > 9 ")
# There were 5151 orders with at least 10 items

# 3. How many customers have ever purchased a medium sized sweater with a discount?
# select with orders.discount > 0 & items.size = 'M' & counting distinct customer_uid 

sqldf( " select count( distinct custs.customer_uid) from  custs 
       inner join orders on orders.customer_uid = custs.customer_uid 
       inner join items on items.order_id = orders.order_id 
       where orders.year = 2018 and orders.discount> 0 and  items.size = 'M'
       ")

# 788 customers made this kind of purchase

# 4. How profitable was our most profitable month?

# calculate net = sell (adjust discount) - return 
# summarize and order by month and year total net
# note that the returns for the last month may not have come in 

# single line for each order_id - returned appears in full; exclude all returned orders
# not clear how a partial return would appear
# net will be sales returned = False

sqldf( "select * from orders where returned = 'True'  order by order_id  limit 100 ")

sqldf( "select * from orders where 
       customer_uid = 'cb6cb4e1ff7ea5f11975376108311148' 
       order by order_id  limit 100 ")



sqldf( "select table1.year, table1.month, ship_net + net as total_net 
        from ( select year, month, sum( orders.shipping_revenue - orders.shipping_cost) as ship_net
        from orders group by year, month ) table1 
        left join ( select year, month, 
              sum( items.quantity * (items.selling_price) * ( 1- orders.discount)  - items.quantity * items.supplier_cost) as net 
              from orders 
              left join items on items.order_id = orders.order_id 
              where returned = 'False'
              group by year, month ) table2 on table1.year = table2.year and table1.month = table2.month
         order by total_net ")


sqldf( " select year, month, sum( orders.shipping_revenue - orders.shipping_cost) as ship_net
        from orders group by year, month 
         order by ship_net ")
# July 2020 appears to be the highest earning month with $60,158


# 5. What is the return rate for business vs. non-business customers?
# summarize by custs.is_business Y/N & orders returned 'True' or 'False'
# count returned orders and total orders (both returned and not returned)

sqldf( " select custs.is_business, 
              count( distinct ( case when orders.returned = 'True' then orders.order_id end )) as returns,
              count( distinct orders.order_id ) as orders,
              1.000 * count( distinct ( case when orders.returned = 'True' then orders.order_id end ))/ count( distinct orders.order_id ) as ret_rate
              from orders 
              left join custs on custs.customer_uid = orders.customer_uid 
              group by custs.is_business ")

# the return rate for business is 6.7% and non business is 4.9%