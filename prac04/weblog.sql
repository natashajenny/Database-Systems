-- COMP3311 Prac Exercise
--
-- Written by: Natasha Jenny


-- Q1: how many page accesses on March 2

create or replace view Q1(nacc) as
select	count(*)
from	accesses
where	acctime >= '2005-03-02' and acctime < '2005-03-03'
;


-- Q2: how many times was the MessageBoard search facility used?

create or replace view Q2(nsearches) as
select	count(*)
from	cccesses
where 	page like 'messageboard%' and params like '%state=search%'
;


-- Q3: on which Tuba lab machines were there incomplete sessions?

create or replace view Q3(hostname) as
select distinct hostname
from	hosts full outer join sessions on (sessions.host = hosts.id)
where	complete='f' and hostname like 'tuba%'
;


-- Q4: min,avg,max bytes transferred in page accesses

create or replace view Q4(min,avg,max) as
select	min(nbytes), avg(nbytes)::integer, max(nbytes)
from	accesses
;


-- Q5: number of sessions from CSE hosts

create or replace view Q5(nhosts) as
select	count(*)
from	sessions
left outer join hosts on (sessions.host = hosts.id)
where	hostname like '%cse.unsw.edu.au'
;


-- Q6: number of sessions from non-CSE hosts

create or replace view Q6(nhosts) as
select	count(*)
from	sessions
left outer join hosts on (sessions.host = hosts.id)
where	hostname not like '%cse.unsw.edu.au'
;


-- Q7: session id and number of accesses for the longest session?

create or replace view sessLength as
select session,count(*) as length
from   accesses
group by session;

create or replace view Q7(session,length) as 
select session,length
from   sessLength
where  length = (select max(length) from sessLength);


-- Q8: frequency of page accesses

create or replace view Q8(page,freq) as
select	distinct page, count(session) as freq
from	accesses group by page
;


-- Q9: frequency of module accesses

create or replace view ModuleAccess as
select session, seq, substring(page from '^[^/]+') as module
from   Accesses;

create or replace view Q9(module,freq) as
select module,count(*)
from   ModuleAccess
group by module
order by count(*) desc
;


-- Q10: "sessions" which have no page accesses

create or replace view Q10(session) as
select	id
from	Sessions
where	not exists (select * from Accesses where session=sessions.id);
;


-- Q11: hosts which are not the source of any sessions

create or replace view Q11(unused) as
select	hostname
from	hosts
left outer join sessions on (hosts.id = sessions.host)
group by hostname having count(sessions.id) = 0
;
