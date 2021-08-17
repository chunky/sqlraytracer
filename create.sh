#!/bin/sh

PGPASSWORD=raytracer
export PGPASSWORD

time psql \
	--host=mills \
	--port=5432 \
	--username=raytracer \
	--dbname=raytracer \
	--file=raytracer.sql \
	--command="\\copy (select * from ppm) to './pgimg.ppm' csv"

xdg-open pgimg.ppm
