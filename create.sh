#!/bin/sh

. ./postgres_connection.sh

# Creating this file overrides which scenes get rendered
scenelist_override=scenelist_override.txt

scenelist=scenelist.txt

outputdir=example_outputs

mkdir -p ${outputdir}

psql \
	--host=${PGHOST} \
	--port=${PGPORT} \
	--username=${PGUSER} \
	--dbname=${PGDB} \
	--file=setup.sql \
	--file=raytracer.sql \
	--command="\\timing" \
	--command="\\copy (select scenename from scene) to './${outputdir}/${scenelist}' csv"

test -e ${scenelist_override} && cp ${scenelist_override} ${outputdir}/${scenelist}

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
	--command="\\copy (select * from ppm) to './${outputdir}/${scenename}.ppm' csv"

  if [ "$(uname)" == "Darwin" ]; then
    open ./${outputdir}/${scenename}.ppm
  else
    xdg-open ./${outputdir}/${scenename}.ppm
  fi
  
  convert ./${outputdir}/${scenename}.ppm ./${outputdir}/${scenename}.png

done < ./${outputdir}/${scenelist}

