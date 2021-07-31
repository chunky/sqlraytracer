CREATE TABLE sphere (sphereid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL, radius REAL NOT NULL);
INSERT INTO sphere (x, y, z, radius) VALUES
                                            (10, 10, 0, 3),
                                            (10, 12, 4, 4),
                                            (-10, -14, 0, 2),
                                            (3, 4, 8, 1)
                                            ;

CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL,
  rot_x REAL NOT NULL, rot_y REAL NOT NULL, rot_z REAL NOT NULL, fov REAL NOT NULL);
INSERT INTO camera (x, y, z, rot_x, rot_y, rot_z, fov) VALUES (0, 0, 0, 0, 0, 0, 60);

CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
INSERT INTO img (res_x, res_y) VALUES (100, 100);

WITH RECURSIVE xs AS (SELECT 0 AS x, 0 AS img_frac_x UNION ALL SELECT x+1, (x+1.0)/img.res_x FROM xs, img WHERE xs.x<img.res_x),
     ys AS (SELECT 0 AS y, 0 AS img_frac_y UNION ALL SELECT y+1, (y+1.0)/img.res_y FROM ys, img WHERE ys.y<img.res_y),
     initialrays(img_x, img_y, origin_x, origin_y, origin_z, dir_x, dir_y, dir_z) AS
         (SELECT xs.x, ys.y, camera.x, camera.y, camera.z,
          FROM camera, xs, ys)
