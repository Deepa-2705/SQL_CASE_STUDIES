select * from sharktank;

truncate  table sharktank;

LOAD DATA INFILE "D:/Profile Data/Downloads/sharktank.csv"
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


select * from sharktank;

-- 1 You Team have to  promote shark Tank India  season 4, The senior come up with the idea to show highest funding domain wise  and
-- you were assigned the task to  show the same.
select * from(
     select   Industry ,Total_Deal_Amount_In_Lakhs,row_number() over(partition by Industry order by  Total_Deal_Amount_In_Lakhs desc)
     as rnk from sharktank
) t where rnk=1;
    
    
-- 2 You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70%
select * ,(female/Male)*100 as ratio from(
	 select Industry, sum(Female_Presenters) as 'Female', sum(Male_Presenters) as 'Male' from sharktank group by Industry having 
     sum(Female_Presenters)>0 and sum(Male_Presenters)>0
)m where (female/Male)*100>70;


-- 3 You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per year sale pitch made, 
-- pitches who received offer and pitches that were converted. Also show the percentage of pitches converted and percentage of pitches
-- received.


select k.Season_Number, k.Total_Pitches, m.Pitches_Received,((Pitches_Received/Total_Pitches)*100) as 'percentage  pitches received',
 l.Pitches_Converted,((Pitches_Converted/Pitches_Received)*100) as 'Percentage pitches converted' from((
		select Season_Number , count(Startup_Name) as 'Total_pitches' from sharktank group by Season_Number
	)k inner join(
		select Season_Number , count(Startup_Name) as 'Pitches_Received' from sharktank where received_offer='yes' group by 
        Season_Number
	)m on k.Season_Number= m.Season_Number inner join(
		select Season_Number , count(Accepted_offer) as 'Pitches_Converted' from sharktank where  Accepted_offer='Yes' group by 
        Season_Number 
	)l on m.Season_Number= l.Season_Number
);


-- 4 As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, how would you 
-- determine the season with the highest average monthly sales and identify the top 5 industries with the highest average monthly 
-- sales during that season to optimize investment decisions?

select * from sharktank;

set @seas= (select Season_Number  from(
   select  Season_Number,round(avg(Monthly_Sales_In_Lakhs),2)as 'average' from sharktank where Monthly_Sales_In_Lakhs!= 'Not_mentioned'
   group by Season_Number  
)k order by average desc limit 1);

select @seas;

select Industry, round(avg(Monthly_Sales_In_Lakhs),2) as average from  sharktank where Season_Number = @seas 
and Monthly_Sales_In_Lakhs!= 'Not_mentioned' group by Industry order by average desc limit 5;


-- 5.As a data scientist at our firm, your role involves solving real-world challenges like identifying industries with consistent 
-- increases in funds raised over multiple seasons. This requires focusing on industries where data is available across all three years.
--  Once these industries are pinpointed, your task is to delve into the specifics, analyzing the number of pitches made, offers 
-- received, and offers converted per season within each industry.



select Industry ,Season_Number , sum('Total_Deal_Amount(in_lakhs)') from sharktank group by Industry ,Season_Number; -- step 1

WITH ValidIndustries AS (
    SELECT 
        Industry, 
        MAX(CASE WHEN Season_Number = 1 THEN Total_Deal_Amount_In_Lakhs END) AS season_1,
        MAX(CASE WHEN Season_Number = 2 THEN Total_Deal_Amount_In_Lakhs END) AS season_2,
        MAX(CASE WHEN Season_Number = 3 THEN Total_Deal_Amount_In_Lakhs END) AS season_3
    FROM sharktank GROUP BY Industry HAVING season_3 > season_2 AND season_2 > season_1 AND season_1 != 0
)  -- step 2 
-- select * from ValidIndustries;
-- select * from sharktank as t  inner join ValidIndustries as v on t.Industry= v.Industry;   -- step 3
SELECT 
    t.Season_Number,
    t.Industry,
    COUNT(t.Startup_Name) AS Total,
    COUNT(CASE WHEN t.Received_Offer = 'Yes' THEN t.Startup_Name END) AS Received,
    COUNT(CASE WHEN t.Accepted_Offer = 'Yes' THEN t.Startup_Name END) AS Accepted
FROM sharktank AS t JOIN ValidIndustries AS v ON t.Industry = v.Industry GROUP BY t.Season_Number, t.Industry;   -- step 4



-- 6. Every shark want to  know in how much year their investment will be returned, so you have to create a system for them , where
-- shark will enter the name of the startup's  and the based on the total deal and quity given in how many years their principal 
-- amount will be returned.

delimiter //
create procedure TOT( in startup varchar(100))
begin
   case 
      when (select Accepted_Offer ='No' from sharktank where Startup_Name = startup)
	        then  select 'Turn Over time cannot be calculated';
	 when (select Accepted_Offer ='yes' and Yearly_Revenue_In_Lakhs = 'Not Mentioned' from sharktank where Startup_Name= startup)
           then select 'Previous data is not available';
	 else
         select Startup_Name,Yearly_Revenue_In_Lakhs,Total_Deal_Amount_In_Lakhs,Total_Deal_Equity_In_Percentage, 
         (Total_Deal_Amount_In_Lakhs)/((Total_Deal_Equity_In_Percentage/100)*Total_Deal_Amount_In_Lakhs) as years
		 from sharktank where Startup_Name= startup;
	
    end case;
end
//
DELIMITER ;

drop procedure TOT;

call TOT('BluePineFoods');


-- 7. In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks," tends to put the
-- money into each deal on average. This comparison helps us see who's the most generous with their investments and how they measure 
-- up against their fellow investors.

select Shark_Name, round(avg(Investment),2)  as 'average' from
(
SELECT Namita_Investment_Amount_In_Lakhs AS Investment, 'Namita' AS Shark_Name FROM sharktank WHERE Namita_Investment_Amount_In_Lakhs > 0
union all
SELECT Vineeta_Investment_Amount_In_Lakhs AS Investment, 'Vineeta' AS Shark_Name FROM sharktank WHERE Vineeta_Investment_Amount_In_Lakhs > 0
union all
SELECT Anupam_Investment_Amount_In_Lakhs AS Investment, 'Anupam' AS Shark_Name FROM sharktank WHERE Anupam_Investment_Amount_In_Lakhs > 0
union all
SELECT Aman_Investment_Amount_In_Lakhs AS Investment, 'Aman' AS Shark_Name FROM sharktank WHERE Aman_Investment_Amount_In_Lakhs > 0
union all
SELECT Peyush_Investment_Amount_In_Lakhs AS Investment, 'peyush' AS Shark_Name FROM sharktank WHERE Peyush_Investment_Amount_In_Lakhs > 0
union all
SELECT Amit_Investment_Amount_In_Lakhs AS Investment, 'Amit' AS Shark_Name FROM sharktank WHERE Amit_Investment_Amount_In_Lakhs > 0
union all
SELECT Ashneer_Investment_Amount_In_Lakhs AS Investment, 'Ashneer' AS Shark_Name FROM sharktank WHERE Ashneer_Investment_Amount_In_Lakhs > 0
)k group by Shark_Name;


select * from sharktank;


-- 8. Develop a system that accepts inputs for the season number and the name of a shark. The procedure will then provide detailed 
-- insights into the total investment made by that specific shark across different industries during the specified season. Additionally
-- it will calculate the percentage of their investment in each sector relative to the total investment in that year, giving a 
-- comprehensive understanding of the shark's investment distribution and impact.

select * from sharktank;

DELIMITER //
create PROCEDURE getseasoninvestment(IN season INT, IN Shark_Name VARCHAR(100))
BEGIN
      
    CASE 
        WHEN Shark_Name = 'Namita' THEN
            set @total1 = (select  sum(Namita_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
            SELECT Industry, sum(Namita_Investment_Amount_In_Lakhs) as 'sum' ,(sum(Namita_Investment_Amount_In_Lakhs)/@total1)*100 as 
            'Percent' FROM sharktank WHERE Season_Number = season AND Namita_Investment_Amount_In_Lakhs > 0 group by Industry;
        WHEN Shark_Name = 'Vineeta' THEN
            set @total2 = (select  sum(Vineeta_Investment_Amount_In_Lakhs_) from sharktank where Season_Number= season );
            SELECT Industry,sum(Vineeta_Investment_Amount_In_Lakhs) as 'sum' ,(sum(Vineeta_Investment_Amount_In_Lakhs)/@total2)*100 as
            'Percent' FROM sharktank WHERE Season_Number = season AND Vineeta_Investment_Amount_In_Lakhs > 0 group by Industry;
        WHEN Shark_Name = 'Anupam' THEN
            set @total3 = (select  sum(Anupam_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
            SELECT Industry,sum(Anupam_Investment_Amount_In_Lakhs) as 'sum',(sum(Anupam_Investment_Amount_In_Lakhs)/@total3)*100 as 
            'Percent' FROM sharktank WHERE Season_Number = season AND Anupam_Investment_Amount_In_Lakhs > 0
            group by Industry;
        WHEN Shark_Name = 'Aman' THEN
            set @total4 = (select  sum(Namita_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
            SELECT Industry,sum(Namita_Investment_Amount_In_Lakhs) as 'sum',(sum(Namita_Investment_Amount_In_Lakhs)/@total4)*100 as 
            'Percent'  FROM sharktank WHERE Season_Number = season AND Aman_Investment_Amount_In_Lakhs > 0
             group by Industry;
        WHEN Shark_Name = 'Peyush' THEN
             set @total5 = (select  sum(Peyush_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
             SELECT Industry,sum(Peyush_Investment_Amount_In_Lakhs) as 'sum',(sum(Peyush_Investment_Amount_In_Lakhs)/@total5)*100 as 
             'Percent' FROM sharktank WHERE Season_Number = season AND Peyush_Investment_Amount_In_Lakhs > 0
             group by Industry;
        WHEN Shark_Name = 'Amit' THEN
			  set @total6 = (select  sum(Amit_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
              SELECT Industry,sum(Amit_Investment_Amount_In_Lakhs) as 'sum' ,(sum('Amit_Investment_Amount_in lakhs_')/@total6)*100 as 
              'Percent'  WHERE Season_Number = season AND Amit_Investment_Amount_In_Lakhs > 0
             group by Industry;
        WHEN Shark_Name = 'Ashneer' THEN
            set @total7 = (select  sum(Ashneer_Investment_Amount_In_Lakhs) from sharktank where Season_Number= season );
            SELECT Industry,sum(Ashneer_Investment_Amount_In_Lakhs) ,(sum(Ashneer_Investment_Amount_In_Lakhs)/@total7)*100 as 
            'Percent' FROM sharktank WHERE Season_Number = season AND Ashneer_Investment_Amount_In_Lakhs > 0
             group by Industry;
        ELSE
            SELECT 'Invalid shark name';
    END CASE;
    
END //
DELIMITER ;


drop procedure getseasoninvestment;
call getseasoninvestment(2, 'Namita');

 set @total = (select  sum(Total_Deal_Amount_In_Lakhs) from sharktank where Season_Number= 1 );
select @total;
-- step 1  -- simple procedure to show output , 
-- step 2 -- industry specific 
-- step 3 -- give output 
-- step 4 -- with total

-- 9. In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio across various industries. 
-- By examining their investment patterns and preferences, we aim to uncover any discernible trends or strategies that may shed light on their decision-making
-- processes and investment philosophies.

select Shark_Name, 
count(distinct Industry) as 'unique industy',
count(distinct concat(Pitchers_City,' ,', Pitchers_State)) as 'unique locations' from 
(
	SELECT Industry, Pitchers_City, Pitchers_State, 'Namita'  as Shark_Name from sharktank where  Namita_Investment_Amount_In_Lakhs > 0
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Vineeta'  as Shark_Name from sharktank where Vineeta_Investment_Amount_In_Lakhs > 0
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam'  as Shark_Name from sharktank where  Anupam_Investment_Amount_In_Lakhs > 0 
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Aman'  as Shark_Name from sharktank where Aman_Investment_Amount_In_Lakhs > 0
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Peyush'  as Shark_Name from sharktank where   Peyush_Investment_Amount_In_Lakhs > 0
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Amit'  as Shark_Name from sharktank where Amit_Investment_Amount_In_Lakhs > 0
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam'  as Shark_Name from sharktank where  Anupam_Investment_Amount_In_Lakhs > 0 
	union all
	SELECT Industry, Pitchers_City, Pitchers_State, 'Ashneer'  as Shark_Name from sharktank where Ashneer_Investment_Amount_In_Lakhs> 0
)t  
group by Shark_Name 
order by  'unique industry' desc ,'unique location' desc;

-- 10.Explain the concept of indexes in MySQL. How do indexes improve query performance, and what factors should be considered when deciding which columns to index in a database table

-- https://dev.mysql.com/doc/refman/8.0/en/mysql-indexes.html
