#!/bin/sh

PGPASSWORD=raytracer
export PGPASSWORD

psql \
	--host=mills \
	--port=5432 \
	--username=raytracer \
	--dbname=raytracer \
	--file=setup.sql \
	--file=raytracer.sql \
	--command="\\timing" \
	--command="\\copy (select * from ppm) to './pgimg.ppm' csv"

xdg-open pgimg.ppm
