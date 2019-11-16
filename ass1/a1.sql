-- 1. List all the company names (and countries) that are incorporated outside Australia.
create or replace view Q1(Name, Country) as
select name, country
from company
where country != 'Australia'
order by name asc;

-- 2. List all the company codes that have more than five executive members on record (i.e., at least six).
create or replace view Q2(Code) as
select code
from executive
group by code
having count(person)>5;

-- 3. List all the company names that are in the sector of "Technology"
create or replace view Q3(Name) as
select name
from company
join category on company.code = category.code
where sector = 'Technology';

-- 4. Find the number of Industries in each Sector
create or replace view Q4(Sector, Number) as
select sector, count(distinct industry) as number
from category group by sector;

-- 5. Find all the executives (i.e., their names) that are affiliated with companies in the sector of "Technology". If an executive is affiliated with more than one company, he/she is counted if one of these companies is in the sector of "Technology".
create or replace view Q5(Name) as
select e.person as Name
from category c
natural join executive e
where c.sector='Technology';

-- 6. List all the company names in the sector of "Services" that are located in Australia with the first digit of their zip code being 2.
create or replace view Q6(Name) as
select co.name
from company co
join category ca on co.code = ca.code
where co.country='Australia' and ca.sector='Services' and co.zip like '2%';

-- 7. Create a database view of the ASX table that contains previous Price, Price change (in amount, can be negative) and Price gain (in percentage, can be negative). (Note that the first trading day should be excluded in your result.) For example, if the PrevPrice is 1.00, Price is 0.85; then Change is -0.15 and Gain is -15.00 (in percentage but you do not need to print out the percentage sign).
create or replace view Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) as
select curr."Date", curr.code, curr.volume,
prev.price as prevprice, curr.price as price, (curr.price - prev.price) as change, (curr.price - prev.price) / prev.price * 100 as gain from asx curr
join asx prev on (curr.code=prev.code) and prev."Date" = (select max("Date") as "Date" from asx where "Date" < curr."Date")
order by code, curr."Date";

-- 8. Find the most active trading stock (the one with the maximum trading volume; if more than one, output all of them) on every trading day. Order your output by "Date" and then by Code.
create view date_max as
select "Date", max(volume)
from asx group by "Date" order by "Date";

create or replace view Q8("Date", Code, Volume) as
select d."Date", a.code, d.max
from date_max d
left join asx a on (d.max=a.volume)
order by d."Date", a.code;

-- 9. Find the number of companies per Industry. Order your result by Sector and then by Industry.
create or replace view Q9(Sector, Industry, Number) as
select sector, industry, count(distinct code)
from category
group by sector, industry
order by sector, industry asc;

-- 10. List all the companies (by their Code) that are the only one in their Industry (i.e., no competitors).
create or replace view Q10(Code, Industry) as
select ca.code, ca.industry
from category ca
join Q9 q on ca.industry = q.industry
where q.number = 1;

-- 11. List all sectors ranked by their average ratings in descending order. AvgRating is calculated by finding the average AvgCompanyRating for each sector (where AvgCompanyRating is the average rating of a company).
create view company_rating as
select ca.code, ca.sector, r.star
from category ca natural join rating r;

create or replace view Q11(Sector, AvgRating) as
select sector, avg(star) as AvgRating
from company_rating
group by sector
order by avgrating desc;

-- 12. Output the person names of the executives that are affiliated with more than one company.
create or replace view Q12(Name) as
select person
from executive
group by person having count(code)>1
order by person asc;

-- 13. Find all the companies with a registered address in Australia, in a Sector where there are no overseas companies in the same Sector. i.e., they are in a Sector that all companies there have local Australia address.
create view company_sector as
select co.code, ca.sector from company co join category ca
on (co.code=ca.code)
where co.country != 'Australia'
order by sector;

create or replace view Q13(Code, Name, Address, Zip, Sector) as
select co.code, co.name, co.address, co.zip, ca.sector
from company co
join category ca on (co.code=ca.code)
where sector not in (select sector from company_sector)
order by co.code asc;

-- 14. Calculate stock gains based on their prices of the first trading day and last trading day (i.e., the oldest "Date" and the most recent "Dte" of the records stored in the ASX table). Order your result by Gain in descending order and then by Code in ascending order.
create view begin_price as
select code, price
from asx
where "Date"=(select min("Date") from asx);

create view end_price as
select code, price
from asx
where "Date"=(select max("Date") from asx);

create or replace view Q14(Code, BeginPrice, EndPrice, Change, Gain) as
select b.code, b.price as beginprice, e.price as endprice, (e.price - b.price) as change, (e.price - b.price)/b.price * 100 as gain
from begin_price b
join end_price e on (b.code=e.code)
order by gain desc, code asc;

-- 15. For all the trading records in the ASX table, produce the following statistics as a database view (where Gain is measured in percentage). AvgDayGain is defined as the summation of all the daily gains (in percentage) then divided by the number of trading days (as noted above, the total number of days here should exclude the first trading day).
create view price_stats as
select code, min(price) as minprice, avg(price) as avgprice, max(price) as maxprice
from asx group by code;

create view gain_stats as
select code, min(gain) as mindaygain, avg(gain) as avgdaygain, max(gain) as maxdaygain
from q7
group by code;

create or replace view Q15(Code, MinPrice, AvgPrice, MaxPrice, MinDayGain, AvgDayGain, MaxDayGain) as
select * from price_stats natural join gain_stats;

-- 16. Create a trigger on the Executive table, to check and disallow any insert or update of a Person in the Executive table to be an executive of more than one company. 

create or replace function checkExecutive() returns trigger
as $$
begin
    if exists(select * from Executive where person = new.person) then
        raise exception 'Already an executive of a company';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger executive_trigger
before insert or update
on Executive for each row
execute procedure checkExecutive();

-- 17. Suppose more stock trading data are incoming into the ASX table. Create a trigger to increase the stock's rating (as Star's) to 5 when the stock has made a maximum daily price gain (when compared with the price on the previous trading day) in percentage within its sector. For example, for a given day and a given sector, if Stock A has the maximum price gain in the sector, its rating should then be updated to 5. If it happens to have more than one stock with the same maximum price gain, update all these stocks' ratings to 5. Otherwise, decrease the stock's rating to 1 when the stock has performed the worst in the sector in terms of daily percentage price gain. If there are more than one record of rating for a given stock that need to be updated, update (not insert) all these records. You may assume that there are at least two trading records for each stock in the existing ASX table, and do not worry about the case that when the ASX table is initially empty. 
create view daily_gain as
select q."Date", q.code, q.gain, ca.sector
from q7 q join category ca on (q.code=ca.code);

create or replace function updateRating() returns trigger
as $$
declare
    _maxGain    numeric;
    _minGain    numeric;
    _gain       numeric;
    _sector     character varying(40);

begin
    _sector := (select sector from category where new.code = category.code);
    _maxGain := (select max(gain) from daily_gain where sector = _sector and "Date" = new."Date");
    _minGain := (select min(gain) from daily_gain where sector = _sector and "Date" = new."Date");
    _gain := (select gain from daily_gain where "Date" = new."Date" and code = new.code);
    if _gain = _maxGain then
        update rating
        set star = 5
        where code = new.code;
    ELSIF _gain = _minGain then
        update rating
        set star = 1
        where code = new.code;    
    end if;  
    return new;  
end;
$$ language plpgsql;

create trigger update_rating
after insert
on asx for each row
execute procedure updateRating();



-- 18. Stock price and trading volume data are usually incoming data and seldom involve updating existing data. However, updates are allowed in order to correct data errors. All such updates (instead of data insertion) are logged and stored in the ASXLog table. Create a trigger to log any updates on Price and/or Voume in the ASX table and log these updates (only for update, not inserts) into the ASXLog table. Here we assume that Date and Code cannot be corrected and will be the same as their original, old values. Timestamp is the date and time that the correction takes place. Note that it is also possible that a record is corrected more than once, i.e., same Date and Code but different Timestamp.

create function updateAsx() returns trigger
as $$
begin
    insert into ASXLog select now()::timestamp, old.*;
    return new;
end;
$$ language plpgsql;

create trigger update_asx
after update on asx
for each row
when (old.volume is distinct from new.volume or old.price is distinct from new.price)
execute procedure updateAsx();
