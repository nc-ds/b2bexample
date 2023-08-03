install.packages('prophet')
install.packages('tidyverse')


library(prophet)
library(tidyverse)

library(lubridate)

# plot order count by day
# plot customer count by day
# plot new customer - first order by day


getwd()
setwd('jiffyshirts')

custs <- read.csv('customers.csv')
items <- read.csv('line_items.csv')
orders <- read.csv('orders.csv')


orders$order_dt = as.POSIXct(orders$order_timestamp,tz= "UTC")
attr(orders$order_dt, "tzone") <- "US/Eastern"
tz(orders$order_dt)

orders$order_month = substr(orders$order_dt,1,7)
orders$order_day = as.Date(orders$order_dt, format='%Y%m%d')
orders$order_year =year(orders$order_day )


summary(custs)
summary(items)
summary(orders)

# get a visual on missing values 
items %>% 
  filter(is.na(selling_price))

#remove the items without a price or cost 
items <- items %>%
  filter(!(is.na(selling_price)))

# Basic exploratory analysis


# customer, business, order, count, discount

# order total - costs and client information

# without discount or shipping
sales <- items %>%
  dplyr::group_by(order_id)%>%
  dplyr::summarize( n=n(),qty = sum(quantity), item_cost = sum(quantity * supplier_cost ), 
                   item_sale = sum(quantity *selling_price)  )

hist(sales$item_net)

summary(sales)
dim(sales)
dim(orders)

sales %>% 
  dplyr::filter(item_sale > 2000)

# order level - discount and shipping included
ordersales <- orders %>% 
  dplyr::left_join(sales, by = 'order_id') %>% 
  dplyr::left_join(custs, by = 'customer_uid') %>%
  mutate(order_costs = item_cost + shipping_cost, order_sale = item_sale*(1-discount) + shipping_revenue,
         order_profit = order_sale - order_costs, margin = order_profit / order_sale)

dim(ordersales)
summary(ordersales)


# Look at discount distribution 
# Profit is asymptotic with discount up to 17.5% but worse for higher discount. 
# suspect discount awarded to larger orders.
# suspect the 0.198 discount is an error. 

table(ordersales$discount)
boxplot(ordersales$order_profit ~ ( ordersales$discount),xlab = 'Discount', ylab = 'Profit' )

boxplot(ordersales$margin ~ ( ordersales$discount),xlab = 'Discount', ylab = 'Margin' )

# monthly new customer - of each business and non business plot distribution


# distinct customer by month/week 
# average purchase by month/week for each customer; measure of trend up or down

tmp <- ordersales %>% 
  group_by(order_month)%>% 
  summarize( n_cust = n_distinct(customer_uid), n_ords = n_distinct(order_id),
             ord_tot = sum(order_sale)) %>% 
  mutate( avg_ord = n_cust/n_ords )

pdf("EDA by Month.pdf")
par(mfrow = c(2,2))
boxplot(tmp$n_cust  ~ tmp$order_month, xlab ='Month', ylab='Customers', main="Customer by Month")
boxplot(tmp$n_ords  ~ tmp$order_month, xlab ='Month', ylab='Orders',main = "Orders by Month")

boxplot(tmp$avg_ord  ~ tmp$order_month, xlab ='Month', ylab='Order by Customer Spend', main = "Average Number of Orders by Customer")
boxplot(tmp$ord_tot  ~ tmp$order_month, xlab ='Month', ylab='Order Size', main = "Average Size of Order")
dev.off()


#sample hold out 10% customers 
dim(custs)
cust_model_list = sample(custs$customer_uid,size = 9000, replace = F)
length(cust_model_list)
cust_valid_list = custs %>% 
  filter(! customer_uid %in% cust_model_list )
dim(cust_valid_list)

summary(ordersales)

custsum = ordersales%>% 
 # filter(returned == 'False') %>%
  filter( customer_uid %in% cust_model_list)%>%
  group_by(customer_uid)%>%
  summarise(n=n(), qty = sum(qty, na.rm =T), order_n = n_distinct(order_id) )

summary(custsum)

dim(custsum)
dim(ordersales)

colnames(ordersales)
summary(ordersales)

daysales = ordersales%>% 
  # filter(returned == 'False') %>%
  filter( customer_uid %in% cust_model_list)%>%
  group_by(order_day)%>%
  summarise(n=n(), qty = sum(qty, na.rm =T), order_n = n_distinct(order_id), profit = sum(order_profit) )


df = daysales %>%
  mutate(y = qty, ds = order_day)%>%
  select(ds, y)

m <- prophet(df)
m <- prophet(df, seasonality.mode = 'multiplicative')

m <- prophet(df, seasonality.mode = 'multiplicative', daily.seasonality=TRUE)
future <- make_future_dataframe(m, periods = 365)

head(future)
forecast <- predict(m, future)
head(forecast)
plot(m,forecast)
prophet_plot_components(m,forecast)
future <- make_future_dataframe(m, periods = 365)
head(future)

