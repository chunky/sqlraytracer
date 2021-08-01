DROP TABLE IF EXISTS sphere;
CREATE TABLE sphere (sphereid INTEGER PRIMARY KEY,
  cx REAL NOT NULL, cy REAL NOT NULL, cz REAL NOT NULL,
  sphere_col REAL NOT NULL, radius REAL NOT NULL, radius2 REAL);
INSERT INTO sphere (cx, cy, cz, sphere_col, radius) VALUES
                                            (4, 3, -10, 0.0, 5),
                                            (-5, 7, 12, 0.3, 7),
                                            (12, -15, -3, 0.7, 8),
                                            (-2, -3, 8, 1.0, 10)
                                            ;
UPDATE sphere SET radius2 = radius*radius WHERE radius2 IS NULL;

DROP TABLE IF EXISTS camera;
CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL,
  rot_x REAL NOT NULL, rot_y REAL NOT NULL, rot_z REAL NOT NULL, fov_rad REAL NOT NULL);
INSERT INTO camera (x, y, z, rot_x, rot_y, rot_z, fov_rad) VALUES (0.0, 0.0, -40.0, 0.0, 0.0, 0.0, PI()/2.0);

DROP TABLE IF EXISTS img;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
INSERT INTO img (res_x, res_y) VALUES (400, 400);

DROP VIEW IF EXISTS do_render;
CREATE VIEW do_render AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     rays(img_x, img_y, depth, ray_col, x1, y1, z1, dir_x, dir_y, dir_z, x2, y2, z2) AS
         (SELECT xs.u, ys.v, 0, NULL, c.x, c.y, c.z,
                SIN(-(fov_rad/2.0)+img_frac_x*fov_rad), SIN(-(fov_rad/2.0)+img_frac_y*fov_rad), 1.0,
                 c.x + SIN(-(fov_rad/2.0)+img_frac_x*fov_rad), c.y + SIN(-(fov_rad/2.0)+img_frac_y*fov_rad), z + 1.0
              FROM camera c, img, xs, ys
        UNION ALL
          SELECT img_x, img_y, depth+1, sphere_col, x1, y1, z1, dir_x, dir_y, dir_z, x2, y2, z2 FROM rays r
           INNER JOIN sphere s ON
               -- https://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
               -- d=len( circ_center-p1 X circ_center-p2) / len(dir_x, dir_y, dir_z)
             s.radius2 >
                   (((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2))*((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2)) +
                    ((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2))*((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2)) +
                    ((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))*((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))) /
                (dir_x*dir_x + dir_y*dir_Y + dir_z*dir_z)
              WHERE depth<3)
 SELECT img_x, img_y, COALESCE(MAX(ray_col), 0.5+0.5*(dir_y/(SQRT(dir_x*dir_x + dir_y*dir_y + dir_z*dir_z)))) AS col FROM rays
    GROUP BY img_y, img_x
    ORDER BY img_y, img_x;

.output img.ppm

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
