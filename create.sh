#!/bin/sh

. ./postgres_connection.sh

# Creating this file overrides which scenes get rendered
scenelist_override=scenelist_override.txt

scenelist=scenelist.txt

psql \
	--host=${PGHOST} \
	--port=${PGPORT} \
	--username=${PGUSER} \
	--dbname=${PGDB} \
	--file=setup.sql \
	--file=raytracer.sql \
	--command="\\timing" \
	--command="\\copy (select scenename from scene) to './${scenelist}' csv"

test -e ${scenelist_override} && cp ${scenelist_override} ${scenelist}

while read scenename
do
  echo ""
  echo "Rendering scene ${scenename}"
  psql \
  	--host=${PGHOST} \
  	--port=${PGPORT} \
  	--username=${PGUSER} \
  	--dbname=${PGDB} \
  	--command="UPDATE camera SET sceneid=(SELECT sceneid FROM scene WHERE scenename='${scenename}')" \
  	--command="\\timing" \
	--command="\\copy (select * from ppm) to './${scenename}.ppm' csv"

  xdg-open ${scenename}.ppm

done < ${scenelist}

