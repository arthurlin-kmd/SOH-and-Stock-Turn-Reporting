SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @reporting_start	int = '20210101';

with cte1 as (
	select	
		fsba.dim_country_key																	Dim_Country_Key,
		dc.country																				Country,
		cast(dd.week_start as date)																Week_Start,
		dp.product_group_code_logical															Product_Group_Code,
		max(dp.product_group_logical)															Product_Group,
		max(CONCAT(dp.product_group_code_logical, N' - ', dp.product_group_logical))			Product_Group_Code_Name,
		dp.business_area_code_logical															Business_Area_Code,
		max(dp.business_area_logical)															Business_Area,
		fpsas.ax_status_is_current																Ax_Status_Is_Current,
		max((Case when fpsas.ax_status_is_current = 1 then 'Current' else 'Clearance' end))		Ax_Status_Is_Current0,
		dp.item_group_code_logical																Item_Group_Code_Logical,
		max(dp.item_group_logical)																Item_Group,
		max(CONCAT(dp.item_group_code_logical, N' - ', dp.item_group_logical))					Item_Group_Code_And_Name,
		dd.acc_week_of_year																		Acc_Week_Of_Year,
		dp.style_code_logical																	Style_Code_Logical,
		max(dp.style_logical)																	Style,
		sum(fsba.total_stock)																	Total_Stock,
		sum((fsba.stock_unit_cost_hedge * fsba.total_stock))									Total_Stock_Hedge_Cost
	from	dim_date	dd							
		left join fact_stock_balance_ax					fsba	on (fsba.dim_date_key = dd.dim_date_key)
		left join vw_fact_product_status_ax_snapshot	fpsas   on (fsba.dim_country_key = fpsas.dim_country_key 
																	and fsba.dim_date_key = fpsas.dim_date_key 
																	and fsba.dim_product_key = fpsas.dim_product_key)
		left join dim_product							dp		on 	(fsba.dim_product_key = dp.dim_product_key)
	
		left join dim_country							dc		on (fsba.dim_country_key = dc.dim_country_key)
	where	(fsba.dim_country_key in (1,2)
				 and dp.business_area_code_logical not in ('AD')
				 and dd.weekday in ('Monday')
				 and dd.dim_date_key >= @reporting_start
				 and dp.item_group_code_logical not in (N'1211', N'1404', N'2113'))
	group by
		fsba.dim_country_key,
		dc.country,	
		dd.week_start,
		dp.product_group_code_logical,
		dp.business_area_code_logical,
		fpsas.ax_status_is_current,
		dp.item_group_code_logical,
		dd.acc_week_of_year,
		dp.style_code_logical
),
cte2 as (
	select	
		fst.dim_country_key													Dim_Country_Key,
		cast(dd.week_start as date)											Week_Start,
		dps.status_name_simplified											Status_Name_Simplified,
		dps.status_description_simplified									Status_Description_Simplified,
		dp.style_code_logical												Style_Code_Logical,
		dp.style_logical													Style,
		sum(fst.cost_of_goods_sold_hedge_cost)								Total_COG_Sold_Hedge_Cost,
		sum(fst.gross_hedge_profit_amount)									Total_Gross_Hedge_Profit,
		sum(fst.sale_amount_excl_gst)										Total_Spend_Excl_GST
	from	fact_sales_trans	fst
		join	dim_product_status	dps
		  on 	(fst.dim_product_status_key = dps.dim_product_status_key)
		join	dim_product	dp
		  on 	(fst.dim_product_key = dp.dim_product_key)
		join	dim_date	dd
		  on 	(fst.dim_date_key = dd.dim_date_key)
		join	dim_country	dc
		  on 	(fst.dim_country_key = dc.dim_country_key)
	where	fst.dim_country_key in (1,2)
			and dd.dim_date_key >= @reporting_start
	group by
		fst.dim_country_key,
		dd.Week_Start,
		dps.status_name_simplified,
		dps.status_description_simplified,
		dp.style_code_logical,
		dp.style_logical
),
cte3 as (
	select
		cte1.*,
		cte2.Total_COG_Sold_Hedge_Cost,
		cte2.Total_Gross_Hedge_Profit,
		cte2.Total_Spend_Excl_GST

	from cte1 
		left join cte2 on cte1.dim_country_key = cte2.dim_country_key
						and cte1.Week_Start = cte2.Week_Start
						and cte1.style_code_logical = cte2.style_code_logical
						and cte1.Ax_Status_Is_Current0 = cte2.Status_Description_Simplified
),
cte4 as (
select
	*,
	sum(case when total_stock > 0 then 1 else 0 end) OVER
		 (partition by country, ax_status_is_current0, style
		  order by week_start 
		  ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) as Number_Wks_Style_Sold,
	AVG(total_stock) OVER 
		 (partition by country, ax_status_is_current0, style
		  order by week_start
		  ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) as Rolling_52_Week_Style_Sold,
	AVG(total_stock_hedge_cost) OVER 
		 (partition by country, ax_status_is_current0, style
		  order by week_start
		  ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) as Rolling_52_Week_Hedge_Cost
from cte3
)
select 
	Dim_Country_Key,
	Country,
	Week_Start,
	Product_Group_Code,
	Product_Group,
	Product_Group_Code_Name,
	Business_Area_Code,
	Business_Area,
	Ax_Status_Is_Current,
	Ax_Status_Is_Current0,
	Item_Group_Code_Logical,
	Item_Group,
	Item_Group_Code_And_Name,
	Acc_Week_Of_Year,
	Style_Code_Logical,
	Style,
	Total_Stock,
	Total_Stock_Hedge_Cost,
	Total_COG_Sold_Hedge_Cost,
	Total_Gross_Hedge_Profit,
	Total_Spend_Excl_GST,
	Number_Wks_Style_Sold,
	case when Number_Wks_Style_Sold = 52 then Rolling_52_Week_Style_Sold else 0 end as Rolling_52_Week_Style_Sold,
	case when Number_Wks_Style_Sold = 52 then Rolling_52_Week_Hedge_Cost else 0 end as Rolling_52_Week_Hedge_Cost

from cte4
order by 
	dim_country_key, ax_status_is_current0, style, week_start
;

