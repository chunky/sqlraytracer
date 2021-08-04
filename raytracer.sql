DROP TABLE IF EXISTS sphere;
CREATE TABLE sphere (sphereid INTEGER PRIMARY KEY,
  cx REAL NOT NULL, cy REAL NOT NULL, cz REAL NOT NULL,
  sphere_col REAL NOT NULL, is_light BOOLEAN NOT NULL,
  radius REAL NOT NULL, radius2 REAL);
INSERT INTO sphere (cx, cy, cz, sphere_col, radius, is_light) VALUES
                                            (4, 3, -10, 0.0, 5, 1),
                                            (-5, 7, 12, 0.3, 7, 0),
                                            (12, -15, -3, 0.4, 8, 0),
                                            (-2, -3, 8, 1.0, 10, 0)
                                            ;
UPDATE sphere SET radius2 = radius*radius WHERE radius2 IS NULL;

DROP TABLE IF EXISTS camera;
CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL,
  rot_x REAL NOT NULL, rot_y REAL NOT NULL, rot_z REAL NOT NULL, fov_rad REAL NOT NULL,
  max_ray_depth INTEGER);
INSERT INTO camera (x, y, z, rot_x, rot_y, rot_z, fov_rad, max_ray_depth) VALUES (0.0, 0.0, -40.0, 0.0, 0.0, 0.0, PI()/2.0, 2);

DROP TABLE IF EXISTS img;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
INSERT INTO img (res_x, res_y) VALUES (350, 350);

DROP VIEW IF EXISTS rays;
CREATE VIEW rays AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     rays(img_x, img_y, depth, max_ray_depth, ray_col, x1, y1, z1, dir_x, dir_y, dir_z, x2, y2, z2, ray_len, hit_light) AS
         (SELECT xs.u, ys.v, 0, max_ray_depth, NULL, c.x, c.y, c.z,
                SIN(-(fov_rad/2.0)+img_frac_x*fov_rad), SIN(-(fov_rad/2.0)+img_frac_y*fov_rad), 1.0,
                 c.x + SIN(-(fov_rad/2.0)+img_frac_x*fov_rad), c.y + SIN(-(fov_rad/2.0)+img_frac_y*fov_rad), z + 1.0,
                 0.0, 0
              FROM camera c, img, xs, ys
        UNION ALL
          SELECT img_x, img_y, depth+1, max_ray_depth, sphere_col, x1, y1, z1, dir_x, dir_y, dir_z, x2, y2, z2,
                 SQRT((cx-x1)*(cx-x1) + (cy-y1)*(cy-y1) + (cz-z1)*(cz-z1)), -- distance to center. fixme should be distance to intersection
                 s.is_light
           FROM rays r
           LEFT JOIN sphere s ON
               -- https://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
               -- d=len( circ_center-p1 X circ_center-p2) / len(dir_x, dir_y, dir_z)
             s.radius2 >
                  ((((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2))*((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2)) +
                    ((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2))*((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2)) +
                    ((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))*((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))) /
                (dir_x*dir_x + dir_y*dir_y + dir_z*dir_z))
              WHERE depth<max_ray_depth AND 0=r.hit_light)
   SELECT *, ROW_NUMBER() OVER (PARTITION BY img_x, img_y, depth ORDER BY ray_len ASC) AS ray_len_idx FROM rays;

DROP VIEW IF EXISTS do_render;
CREATE VIEW do_render AS
 SELECT A.img_x, A.img_y, COALESCE(MAX(A.ray_col * 1.0/A.depth), 0.5+0.5*(A.dir_y/(SQRT(A.dir_x*A.dir_x + A.dir_y*A.dir_y + A.dir_z*A.dir_z)))) AS col
    FROM rays A LEFT JOIN rays B ON A.img_x=B.img_x AND A.img_y=B.img_y AND A.ray_len_idx=1 AND A.depth=B.depth-1
    GROUP BY A.img_y, A.img_x
    ORDER BY A.img_y, A.img_x;

.output img.ppm

DROP VIEW IF EXISTS ppm;
CREATE VIEW ppm AS
 WITH maxcol(mc) AS (SELECT 255)
    SELECT 'P3'
  UNION ALL
    SELECT res_x || ' ' || res_y || ' ' || mc FROM img, maxcol
  UNION ALL
    SELECT CAST(col*mc AS INTEGER) || ' ' || CAST(col*mc AS INTEGER) || ' ' || CAST(col*mc AS INTEGER)
      FROM do_render, maxcol;
  ;
SELECT * FROM ppm;
