/*
Report: Status SOH Historical Data by Style
Job: 9631
Report Cache Used: No

Number of Columns Returned:		20
Number of Temp Tables:		0

Total Number of Passes:		2
Number of SQL Passes:		2
Number of Analytical Passes:		0

Tables Accessed:
dim_country
dim_date
dim_product
fact_stock_balance_ax
vw_fact_product_status_ax_snapshot


SQL Statements:
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


select	a11.dim_date_key  dim_date_key,
	max(a14.date_text)  date_text,
	a13.product_group_code_logical  product_group_code,
	max(a13.product_group_logical)  product_group,
	max(CONCAT(a13.product_group_code_logical, N' - ', a13.product_group_logical))  product_group_code_name,
	a11.dim_product_key  dim_product_key,
	a13.business_area_code_logical  business_area_code,
	max(a13.business_area_logical)  business_area,
	a12.ax_status_is_current  ax_status_is_current,
	max((Case when a12.ax_status_is_current = 1 then 'Current' else 'Clearance' end))  ax_status_is_current0,
	a13.item_group_code_logical  item_group_code_logical,
	max(a13.item_group_logical)  item_group,
	max(CONCAT(a13.item_group_code_logical, N' - ', a13.item_group_logical))  item_group_code_and_name,
	a14.acc_week_of_year  acc_week_of_year,
	a13.style_code_logical  style_code_logical,
	max(a13.style_logical)  style,
	a11.dim_country_key  dim_country_key,
	max(a15.country)  country,
	sum(a11.total_stock)  WJXBFS1,
	sum((a11.stock_unit_cost_hedge * a11.total_stock))  WJXBFS2
from	fact_stock_balance_ax	a11
	join	vw_fact_product_status_ax_snapshot	a12
	  on 	(a11.dim_country_key = a12.dim_country_key and 
	a11.dim_date_key = a12.dim_date_key and 
	a11.dim_product_key = a12.dim_product_key)
	join	dim_product	a13
	  on 	(a11.dim_product_key = a13.dim_product_key)
	join	dim_date	a14
	  on 	(a11.dim_date_key = a14.dim_date_key)
	join	dim_country	a15
	  on 	(a11.dim_country_key = a15.dim_country_key)
where	(a11.dim_country_key in (2)
 and a13.business_area_code_logical not in ('AD')
 and a14.weekday in ('Monday')
  and a14.full_date_datetime between  '2018-08-01' and DATEADD(day,7,getdate())
 and a13.item_group_code_logical not in (N'1211', N'1404', N'2113'))
group by	a11.dim_date_key,
	a13.product_group_code_logical,
	a11.dim_product_key,
	a13.business_area_code_logical,
	a12.ax_status_is_current,
	a13.item_group_code_logical,
	a14.acc_week_of_year,
	a13.style_code_logical,
	a11.dim_country_key