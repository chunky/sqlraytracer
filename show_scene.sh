#!/bin/sh

. ./postgres_connection.sh

show_scene_dir=show_scene

scenelist=scenelist.txt

psql \
        --host=${PGHOST} \
        --port=${PGPORT} \
        --username=${PGUSER} \
        --dbname=${PGDB} \
        --file=setup.sql \
        --file=raytracer.sql \
        --command="\\timing" \
        --command="\\copy (select scenename from scene) to './${show_scene_dir}/${scenelist}' csv"

mkdir -p ${show_scene_dir}
cd ${show_scene_dir}

while read scenename
do
  echo ""
  echo "Rendering scene ${scenename}"


psql \
	--host=${PGHOST} \
        --port=${PGPORT} \
        --username=${PGUSER} \
        --dbname=${PGDB} \
        --command="\\copy (select sphereid, cx, cy, cz, radius from sphere inner join scene s on s.sceneid=sphere.sceneid where s.scenename='${scenename}') to './spheres.csv' with csv header" \

img_size=2048

scale_vector=5

cat <<EOH > gnuplot.gp
set terminal png size ${img_size},${img_size}
set xrange [-60:60]
set yrange [-60:60]
set datafile separator ','
set key autotitle columnhead

set output '${scenename}_xz.png'
set xlabel "X"
set ylabel "Z"
plot \\
        "spheres.csv" u 2:4:5 w circles t 'spheres'

set output '${scenename}_zx.png'
set xlabel "Z"
set ylabel "X"
plot \\
        "spheres.csv" u 4:2:5 w circles t 'spheres'

set output '${scenename}_xy.png'
set xlabel "X"
set ylabel "Y"
plot \\
        "spheres.csv" u 2:3:5 w circles t 'spheres'

set output '${scenename}_yx.png'
set xlabel "Y"
set ylabel "X"
plot \\
        "spheres.csv" u 3:2:5 w circles t 'spheres'

set output '${scenename}_yz.png'
set xlabel "Y"
set ylabel "Z"
plot \\
        "spheres.csv" u 3:4:5 w circles t 'spheres'

set output '${scenename}_zy.png'
set xlabel "Z"
set ylabel "Y"
plot \\
        "spheres.csv" u 4:3:5 w circles t 'spheres'

set output '${scenename}_3view.png'
set xrange [-120:120]
set yrange [-120:120]
set zrange [-120:120]
set xlabel "X"
set ylabel "Y"
set zlabel "Z"
splot \\
	"spheres.csv" u 2:3:4:5 w circles t 'spheres'

set terminal qt
replot

EOH

gnuplot gnuplot.gp

montage \
	-tile 2x2 \
	-geometry ${img_size}x${img_size} \
	${scenename}_xy.png \
       	${scenename}_zy.png \
       	${scenename}_xz.png \
       	${scenename}_3view.png \
	${scenename}.png

xdg-open ${scenename}.png

done < ./${scenelist}
