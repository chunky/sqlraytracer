#!/bin/sh

debug_dir=debug_rays
mkdir -p ${debug_dir}
cd ${debug_dir}

PGPASSWORD=raytracer
export PGPASSWORD

psql \
        --host=localhost \
        --port=5432 \
        --username=raytracer \
        --dbname=raytracer \
        --command="\\copy (select sphere.* from sphere inner join camera c ON c.sceneid=sphere.sceneid) to './spheres.csv' csv" \
	--command="\\copy (select * from rays WHERE 1=depth) to './rays.csv' csv"

gnuplot <<EOH
set terminal png size 1024,1024
set xrange [-60:60]
set yrange [-60:60]
set datafile separator ','

set output 'debug_rays_xz.png'
plot \
        "spheres.csv" u 2:4:5 w circles t 'spheres', \
        "rays.csv" u 11:13:14:16 w vectors filled head t 'rays'

set output 'debug_rays_xy.png'
plot \
        "spheres.csv" u 2:3:5 w circles t 'spheres', \
        "rays.csv" u 11:12:14:15 w vectors t 'rays'

set output 'debug_rays_yz.png'
plot \
        "spheres.csv" u 3:4:5 w circles t 'spheres', \
        "rays.csv" u 12:13:15:16 w vectors t 'rays'
EOH

xdg-open debug_rays_xz.png

