-- COMP3311 19s1 Assignment 2
--
-- updates.sql
--
-- Written by Natasha Jenny (z5141492), Apr 2019

--  This script takes a "vanilla" imdb database (a2.db) and
--  make all of the changes necessary to make the databas
--  work correctly with your PHP scripts.
--  
--  Such changes might involve adding new views,
--  PLpgSQL functions, triggers, etc. Other changes might
--  involve dropping or redefining existing
--  views and functions (if any and if applicable).
--  You are not allowed to create new tables for this assignment.
--  
--  Make sure that this script does EVERYTHING necessary to
--  upgrade a vanilla database; if we need to chase you up
--  because you forgot to include some of the changes, and
--  your system will not work correctly because of this, you
--  will lose half of your assignment 2 final mark as penalty.
--

UPDATE movie SET title = TRIM (title);

create or replace view movie_stats as
select m.id as movie_id, m.director_id, m.title, m.year, m.content_rating, m.lang, r.imdb_score, r.num_voted_users as votes
from movie m
join rating r on (m.id = r.movie_id);

create or replace view movie_genres as
select m.id as movie_id, g.genre from movie m join genre g on m.id = g.movie_id;

create or replace view all_genres as
select m.movie_id, title, year, imdb_score, votes, string_agg(genre, ',') as genres from movie_stats m left join movie_genres g on m.movie_id = g.movie_id group by m.movie_id, title, year, imdb_score, votes;

create or replace view genres_keywords as
select title, year, imdb_score, votes, genres, string_agg(keyword, ',') as keywords from all_genres g left join keyword k on g.movie_id = k.movie_id group by g.movie_id, title, year, imdb_score, votes, genres;

create or replace view movie_actor as
select m.movie_id, m.title, m.director_id, m.content_rating, m.imdb_score, m.year, a.id as actor_id, a.name
from acting t
join movie_stats m on (t.movie_id = m.movie_id)
join actor a on (t.actor_id = a.id)
order by a.name;

create or replace view actortoactor as
select x.actor_id A_ID, x.name::text actorA, x.title || ' (' || x.year || ')' as movie, y.actor_id B_ID, y.name::text actorB from movie_actor x
join movie_actor y on (x.title=y.title and x.name != y.name);

create or replace view movie_details as
select m.title, d.name as director, m.year, m.content_rating, m.imdb_score, m.name as actor
from movie_actor m
left join director d on (m.director_id = d.id);