#!/bin/sh

. ./postgres_connection.sh

debug_dir=debug_rays
mkdir -p ${debug_dir}
cd ${debug_dir}

psql \
	--host=${PGHOST} \
        --port=${PGPORT} \
        --username=${PGUSER} \
        --dbname=${PGDB} \
        --command="\\copy (select sphereid, cx, cy, cz, radius from sphere inner join camera c ON c.sceneid=sphere.sceneid) to './spheres.csv' with csv header" \
	--command="\\copy (select * from rays WHERE img_x=125 AND img_y between 120 and 195 and 0=img_y%5) to './rays.csv' with csv header"

img_size=2048

scale_vector=5

cat <<EOH > gnuplot.gp
set terminal png size ${img_size},${img_size}
set xrange [-60:60]
set yrange [-60:60]
set datafile separator ','
set key autotitle columnhead

set output 'debug_rays_xz.png'
set xlabel "X"
set ylabel "Z"
plot \\
        "spheres.csv" u 2:4:5 w circles t 'spheres', \\
	"rays.csv" u 12:14:(${scale_vector}*\$19/\$22):(${scale_vector}*\$21/\$22) w vectors t 'normals', \\
	"rays.csv" u 12:14:(${scale_vector}*\$15):(${scale_vector}*\$17) w vectors filled head t 'rays'

set output 'debug_rays_zx.png'
set xlabel "Z"
set ylabel "X"
plot \\
        "spheres.csv" u 4:2:5 w circles t 'spheres', \\
	"rays.csv" u 14:12:(${scale_vector}*\$21/\$22):(${scale_vector}*\$19/\$22) w vectors t 'normals', \\
	"rays.csv" u 14:12:(${scale_vector}*\$17):(${scale_vector}*\$15) w vectors filled head t 'rays'

set output 'debug_rays_xy.png'
set xlabel "X"
set ylabel "Y"
plot \\
        "spheres.csv" u 2:3:5 w circles t 'spheres', \\
	"rays.csv" u 12:13:(${scale_vector}*\$19/\$22):(${scale_vector}*\$20/\$22) w vectors t 'normals', \\
	"rays.csv" u 12:13:(${scale_vector}*\$15):(${scale_vector}*\$16) w vectors t 'rays'

set output 'debug_rays_yx.png'
set xlabel "Y"
set ylabel "X"
plot \\
        "spheres.csv" u 3:2:5 w circles t 'spheres', \\
	"rays.csv" u 13:12:(${scale_vector}*\$20/\$22):(${scale_vector}*\$19/\$22) w vectors t 'normals', \\
	"rays.csv" u 13:12:(${scale_vector}*\$16):(${scale_vector}*\$15) w vectors t 'rays'

set output 'debug_rays_yz.png'
set xlabel "Y"
set ylabel "Z"
plot \\
        "spheres.csv" u 3:4:5 w circles t 'spheres', \
	"rays.csv" u 13:14:(${scale_vector}*\$20/\$22):(${scale_vector}*\$21/\$22) w vectors t 'normals', \\
	"rays.csv" u 13:14:(${scale_vector}*\$16):(${scale_vector}*\$17) w vectors t 'rays'

set output 'debug_rays_zy.png'
set xlabel "Z"
set ylabel "Y"
plot \\
        "spheres.csv" u 4:3:5 w circles t 'spheres', \\
	"rays.csv" u 14:13:(${scale_vector}*\$21/\$22):(${scale_vector}*\$20/\$22) w vectors t 'normals', \\
	"rays.csv" u 14:13:(${scale_vector}*\$17):(${scale_vector}*\$16) w vectors t 'rays'

set output '3view.png'
set xrange [-120:120]
set yrange [-120:120]
set zrange [-120:120]
set xlabel "X"
set ylabel "Y"
set zlabel "Z"
splot \\
	"spheres.csv" u 2:3:4:5 w circles t 'spheres', \\
	"rays.csv" u 12:13:14:(${scale_vector}*\$19/\$22):(${scale_vector}*\$20/\$22):(${scale_vector}*\$21/\$22) w vectors filled head t 'normals', \\
	"rays.csv" u 12:13:14:(${scale_vector}*\$15):(${scale_vector}*\$16):(${scale_vector}*\$17) w vectors filled head t 'rays'

set terminal qt
replot

EOH

gnuplot gnuplot.gp

montage \
	-tile 2x2 \
	-geometry ${img_size}x${img_size} \
	debug_rays_xy.png \
       	debug_rays_zy.png \
       	debug_rays_xz.png \
       	3view.png \
	debug_rays.png

xdg-open debug_rays.png

