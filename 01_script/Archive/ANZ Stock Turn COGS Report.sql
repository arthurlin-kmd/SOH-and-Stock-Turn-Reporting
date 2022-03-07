/*
Report: ANZ Stock Turn COGS Report
Job: 9649
Report Cache Used: No

Number of Columns Returned:		17
Number of Temp Tables:		0

Total Number of Passes:		2
Number of SQL Passes:		2
Number of Analytical Passes:		0

Tables Accessed:
dim_country
dim_date
dim_product
dim_product_status
fact_sales_trans


SQL Statements:
*/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


select	a14.acc_week_of_year  acc_week_of_year,
	a13.business_area_code_logical  business_area_code,
	max(a13.business_area_logical)  business_area,
	a13.product_group_code_logical  product_group_code,
	max(a13.product_group_logical)  product_group,
	a11.dim_date_key  dim_date_key,
	max(a14.date_text)  date_text,
	a14.acc_fin_year  acc_fin_year,
	max(a14.acc_year_start)  acc_year_start_date_datatype,
	a11.dim_product_key  dim_product_key,
	a12.status_name_simplified  status_name_simplified,
	max(a12.status_description_simplified)  status_description_simplified,
	a11.dim_country_key  dim_country_key,
	max(a15.country)  country,
	sum(a11.cost_of_goods_sold_hedge_cost)  Total_COG_Sold_Hedge_Cost,
	sum(a11.gross_hedge_profit_amount)  Total_Gross_Hedge_Profit,
	sum(a11.sale_amount_excl_gst)  Total_Spend_Excl_GST
from	fact_sales_trans	a11
	join	dim_product_status	a12
	  on 	(a11.dim_product_status_key = a12.dim_product_status_key)
	join	dim_product	a13
	  on 	(a11.dim_product_key = a13.dim_product_key)
	join	dim_date	a14
	  on 	(a11.dim_date_key = a14.dim_date_key)
	join	dim_country	a15
	  on 	(a11.dim_country_key = a15.dim_country_key)
where	(a14.full_date_datetime between '2022-01-01' and '2022-02-20'
 and a11.dim_country_key in (1, 2))
group by	a14.acc_week_of_year,
	a13.business_area_code_logical,
	a13.product_group_code_logical,
	a11.dim_date_key,
	a14.acc_fin_year,
	a11.dim_product_key,
	a12.status_name_simplified,
	a11.dim_country_key

/*
[Analytical engine calculation steps:
	1.  Calculate metric: <Gross Profit % (Hedge Rate)> in the dataset
	2.  Perform dynamic aggregation over <Date, Product: Key>
	3.  Calculate metric: <Gross Profit % (Hedge Rate)> at original data level in the view
	4.  Calculate subtotal: <Total> 
	5.  Calculate metric: <Gross Profit % (Hedge Rate)> at subtotal levels in the view
	6.  Perform cross-tabbing
]
*/