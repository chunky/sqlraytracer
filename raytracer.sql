DROP TABLE IF EXISTS sphere;
CREATE TABLE sphere (sphereid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL, radius REAL NOT NULL);
INSERT INTO sphere (x, y, z, radius) VALUES
                                            (10, 10, 8, 3),
                                            (10, 12, 4, 4),
                                            (-10, -14, 6, 2),
                                            (3, 4, 8, 1)
                                            ;

DROP TABLE IF EXISTS camera;
CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL,
  rot_x REAL NOT NULL, rot_y REAL NOT NULL, rot_z REAL NOT NULL, fov_rad REAL NOT NULL);
INSERT INTO camera (x, y, z, rot_x, rot_y, rot_z, fov_rad) VALUES (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, PI()/3.0);

DROP TABLE IF EXISTS img;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
INSERT INTO img (res_x, res_y) VALUES (400, 400);

DROP VIEW IF EXISTS do_render;
CREATE VIEW do_render AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     initialrays(img_x, img_y, x, y, z, dir_x, dir_y, dir_z) AS
         (SELECT xs.u, ys.v, camera.x, camera.y, camera.z,
                sin(-(fov_rad/2.0)+img_frac_x*camera.fov_rad), sin(-(fov_rad/2.0)+img_frac_y*camera.fov_rad), 1.0
          FROM camera, img, xs, ys),
     colors AS (SELECT *, 0.5+(dir_y/(SQRT(dir_x*dir_x + dir_y*dir_y + dir_z*dir_z))) AS col FROM initialrays)
 SELECT img_x, img_y, col FROM colors ORDER BY img_y, img_x;

DROP VIEW IF EXISTS ppm;
CREATE VIEW ppm AS
    SELECT 'P3'
  UNION ALL
    SELECT res_x || ' ' || res_y || ' 255' FROM img
  UNION ALL
    SELECT CAST(col*255 AS INTEGER) || ' ' || CAST(col*255 AS INTEGER) || ' ' || CAST(col*255 AS INTEGER)
      FROM do_render;
  ;
SELECT * FROM ppm;

.output img.ppm
SELECT * FROM ppm;
