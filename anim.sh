#!/bin/sh

. ./postgres_connection.sh

scenename="busyday"
outfolder=anim
dt=0.05
gravity=-9.8

psql \
	--host=${PGHOST} \
	--port=${PGPORT} \
	--username=${PGUSER} \
	--dbname=${PGDB} \
	--file=setup.sql \
	--file=raytracer.sql \
	--command="UPDATE camera SET sceneid=(SELECT sceneid FROM scene WHERE scenename='${scenename}')"

mkdir -p ${outfolder}

for frame in `seq -w 0 1000`
do
  echo "Frame ${frame}"
  psql \
  	--host=${PGHOST} \
  	--port=${PGPORT} \
  	--username=${PGUSER} \
  	--dbname=${PGDB} \
	--command="INSERT INTO updateworld(dt, grav_x, grav_y, grav_z) VALUES (${dt}, 0.0, ${gravity}, 0.0)" \
  	--command="\\timing" \
	--command="\\copy (select * from ppm) to './${outfolder}/${scenename}_${frame}.ppm' csv"

done

ffmpeg \
	-r 25 \
	-i ./${outfolder}/${scenename}_%d.ppm \
	-vcodec libx264 \
	-crf 25 \
       	-pix_fmt yuv420p \
	./${outfolder}/${scenename}.mp4

