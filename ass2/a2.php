<?php

define("LIB_DIR","/import/adams/1/cs3311/public_html/19s1/assignments/a2");
require_once(LIB_DIR."/db.php");

// Your DB connection parameters, e.g., database name
//
define("DB_CONNECTION","dbname=a2");


function direct_path($db, $degree, $actorA, $actorB)
{
	$q = "with recursive costars(path) as (
	select actorA || '_' || movie || '_' || actorB as path, array[actorA, actorB] as actors, actorB, 1 as level from actortoactor where lower(actorA) = lower(%s)
	union
	select path || '_' || movie || '_' || y.actorB, actors || y.actorA, y.actorB, level+1 from costars, actortoactor y where y.actorA = costars.actorB and y.actorB <> all(actors) and costars.level < %d
	)
	select path from costars where lower(actorB) = lower(%s)";

	$r = dbQuery($db, mkSQL($q, $actorA, $degree, $actorB));
	return $r;
}


function indirect_path($db, $actor, $degree)
{
	$q = "with recursive costars(path) as (
	select actorA || '_' || movie || '_' || actorB as path, array[actorA, actorB] as actors, actorB, 1 as level from actortoactor where lower(actorA) = lower(%s)
	union
	select path || '_' || movie || '_' || y.actorB, actors || y.actorA, y.actorB, level+1 from costars, actortoactor y where y.actorA = costars.actorB and y.actorB <> all(actors) and costars.level < %d
	)
	select path from costars where level=%d";

	$r = dbQuery($db, mkSQL($q, $actor, $degree, $degree));
	return $r;
}

?>
