# Jiffyshirts
Take home interview data analysis

[Part A](https://github.com/nc-ds/b2bexample/blob/main/data-summary.R) is carried out in R with inline results to the questions asked.

[Part B](https://github.com/nc-ds/b2bexample/blob/main/partB-analysis.R) is also carried out in R. 

Some [EDA](https://github.com/nc-ds/b2bexample/blob/main/EDA%20by%20Month.pdf) of orders and customers. The number of customers are increasing, the number of orders are increasing. The averge sale by customer is also increasing. The number of orders by customer was higher in early years, but appears to have stabilized. The order history is provided up to December of 2020. The economics for the USA have changed since 2021. It would be important to look at more recent sales to confirm any of these patterns. 

![EDA](https://github.com/nc-ds/b2bexample/blob/main/EDA%20by%20Month.pdf)

A basic [sales forecast](https://github.com/nc-ds/b2bexample/blob/main/forecast%20count%20of%20orders.pdf) is carried out for the number or daily orders using Prophet. There is a continuous increase in sales using this basic apporach. Forecasting using the past using only the historical count does not account for any economic pressures or additional marketing campaigns. The next steps looking at customr level sales can incorporate these pressures more readily, by adjusting the churn probability, or sales per customer, or total number of customers. 

![sales forecast](https://github.com/nc-ds/b2bexample/blob/main/forecast%20count%20of%20orders.pdf)

The next steps would be to look at a customer level to evaluate frequency, order size. Using a churn model to assess if the customer will shop in the upcoming purchase window, a conditional spend model is used to determine the spend of the customer if they do order.  
