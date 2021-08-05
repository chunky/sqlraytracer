#!/bin/sh

./sqlite3 -init raytracer.sql <<EOH
.output img.ppm
SELECT * FROM ppm;
EOH
xdg-open img.ppm


