DROP TABLE IF EXISTS sphere CASCADE;
CREATE TABLE sphere (sphereid INTEGER PRIMARY KEY,
  cx DOUBLE PRECISION NOT NULL, cy DOUBLE PRECISION NOT NULL, cz DOUBLE PRECISION NOT NULL,
  sphere_col_r DOUBLE PRECISION NOT NULL, sphere_col_g DOUBLE PRECISION NOT NULL, sphere_col_b DOUBLE PRECISION NOT NULL,
  is_light BOOLEAN NOT NULL,
  radius DOUBLE PRECISION NOT NULL, radius2 DOUBLE PRECISION);
INSERT INTO sphere (sphereid, cx, cy, cz, sphere_col_r, sphere_col_g, sphere_col_b, radius, is_light) VALUES
                                            (1, 4, 3, -10, 0.01, 0.01, 0.01, 5, CAST(1 AS BOOLEAN)),
                                            (2, -5, 7, 12, 0.8, 0.0, 0.0, 7, CAST(0 AS BOOLEAN)),
                                            (3, 12, -15, -3, 0.0, 0.9, 0.0, 8, CAST(0 AS BOOLEAN)),
                                            (4, -2, -3, 8, 0.0, 0.0, 1.0, 10, CAST(0 AS BOOLEAN)),
                                            (5, -8, -3, 8, 0.95, 0.95, 0.95, 2, CAST(0 AS BOOLEAN))
                                            ;
UPDATE sphere SET radius2 = radius*radius WHERE radius2 IS NULL;

DROP TABLE IF EXISTS camera CASCADE;
CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x DOUBLE PRECISION NOT NULL, y DOUBLE PRECISION NOT NULL, z DOUBLE PRECISION NOT NULL,
  rot_x DOUBLE PRECISION NOT NULL, rot_y DOUBLE PRECISION NOT NULL, rot_z DOUBLE PRECISION NOT NULL,
  fov_rad_x DOUBLE PRECISION NOT NULL, fov_rad_y DOUBLE PRECISION NOT NULL,
  max_ray_depth INTEGER NOT NULL);
INSERT INTO camera (cameraid, x, y, z, rot_x, rot_y, rot_z, fov_rad_x, fov_rad_y, max_ray_depth)
  VALUES (1, 0.0, 0.0, -80.0, 0.0, 0.0, 0.0, PI()/2.0, PI()/2.0, 1);

DROP TABLE IF EXISTS img CASCADE;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
    INSERT INTO img (res_x, res_y) VALUES (350, 350);


-- Skipped bits:
--   "Front faces vs back faces"
--   "antialiasing"


DROP VIEW IF EXISTS rays CASCADE;
CREATE VIEW rays AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     rs(img_x, img_y, depth, max_ray_depth,
          ray_col_r, ray_col_g, ray_col_b,
          x1, y1, z1,
          dir_x, dir_y, dir_z,
          dir_lensquared,
          ray_len, hit_light, was_miss, ray_len_idx) AS
        -- Send out initial set of rays from camera
         (SELECT xs.u, ys.v, 0, max_ray_depth,
                CAST(NULL AS DOUBLE PRECISION), CAST(NULL AS DOUBLE PRECISION), CAST(NULL AS DOUBLE PRECISION),
                 c.x, c.y, c.z,
                 SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x), SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y), CAST(1.0 AS DOUBLE PRECISION),
                 SQRT(SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x)*SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x) +
                      SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y)*SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y) + 1.0),
                 CAST(1.0 AS DOUBLE PRECISION), CAST(0 AS BOOLEAN), CAST(0 AS BOOLEAN), CAST(1 AS BIGINT)
              FROM camera c, img, xs, ys
        UNION ALL
         -- Collide all rays with spheres
          SELECT img_x, img_y, depth+1, max_ray_depth,
                 CASE WHEN discrim>0 THEN sphere_col_r*0.5*(1+norm_x/norm_len) ELSE dir_y END,
                 CASE WHEN discrim>0 THEN sphere_col_g*0.5*(1+norm_y/norm_len) ELSE dir_y END,
                 CASE WHEN discrim>0 THEN sphere_col_b*0.5*(1+norm_z/norm_len) ELSE dir_y END,
                 -- x1, y1, z1
                 x1+dir_x*t,
                 y1+dir_y*t,
                 z1+dir_z*t,
                 -- dir_x, dir_y, dir_z
                 -dir_x+2*(cx-x1+dir_x*t),
                 -dir_y+2*(cy-y1+dir_y*t),
                 -dir_z+2*(cz-z1+dir_z*t),
                 dir_lensquared,
                 -- distance to center. fixme should be distance to intersection
                 SQRT((cx-x1)*(cx-x1) + (cy-y1)*(cy-y1) + (cz-z1)*(cz-z1)),
                 is_light, discrim<0, ROW_NUMBER() OVER (PARTITION BY img_x, img_y, depth+1 ORDER BY SQRT((cx-x1)*(cx-x1) + (cy-y1)*(cy-y1) + (cz-z1)*(cz-z1)))
           FROM rs
           LEFT JOIN LATERAL
               (SELECT s.*, ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                                - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2) discrim,
                       (-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                        -SQRT(ABS(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                            - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared)) t
                         FROM sphere s
                       ) hit_sphere ON discrim>0
           LEFT JOIN LATERAL
               (SELECT x1+dir_x*t AS hit_x, y1+dir_y*t AS hit_y, z1+dir_z*t AS hit_z,
                       x1+dir_x*t-cx AS norm_x, y1+dir_y*t-cy AS norm_y, z1+dir_z*t-cz AS norm_z,
                       SQRT((x1+dir_x*t-cx)*(x1+dir_x*t-cx)+(y1+dir_y*t-cy)*(y1+dir_y*t-cy)+(z1+dir_z*t-cz)*(z1+dir_z*t-cz)) AS norm_len
               ) sphere_normal ON discrim>0
              WHERE depth<max_ray_depth AND NOT rs.hit_light AND NOT was_miss AND ray_len_idx=1)
   SELECT * FROM rs WHERE ray_len_idx=1;

         -- double hit_sphere(const point3& center, double radius, const ray& r) {
         --     vec3 oc = r.origin() - center;
         --            x1-cx, y1-cy, z1-cz
         --     auto a = dot(r.direction(), r.direction());
         --            dir_lensquared
         --     auto half_b = dot(oc, r.direction());
         --            ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
         --     auto c = dot(oc, oc) - radius*radius;
         --            (x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2
         --     auto discriminant = half_b*half_b - a*c;
         --            ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
         --               - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)
         --     if (discriminant < 0) {
         --         return -1.0;
         --     } else {
         --         return (-half_b - sqrt(discriminant) ) / a;
         --            -((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
         --            -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
         --                 - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared
         --     }
         -- }

DROP VIEW IF EXISTS do_render;
CREATE VIEW do_render AS
 SELECT A.img_x, A.img_y,
         COALESCE(MAX(A.ray_col_r * 1.0/A.depth)) col_r, COALESCE(MAX(A.ray_col_g * 1.0/A.depth)) col_g, COALESCE(MAX(A.ray_col_b * 1.0/A.depth)) col_b
    FROM rays A LEFT JOIN rays B ON A.img_x=B.img_x AND A.img_y=B.img_y AND A.ray_len_idx=1 AND A.depth=B.depth-1
    GROUP BY A.img_y, A.img_x
    ORDER BY A.img_y, A.img_x;

DROP VIEW IF EXISTS ppm;
CREATE VIEW ppm AS
 WITH maxcol(mc) AS (SELECT 255)
    SELECT 'P3'
  UNION ALL
    SELECT res_x || ' ' || res_y || ' ' || mc FROM img, maxcol
  UNION ALL
    SELECT CAST((mc+col_r*mc)/2 AS INTEGER) || ' ' || CAST((mc+col_g*mc)/2 AS INTEGER) || ' ' || CAST((mc+col_b*mc)/2 AS INTEGER)
      FROM do_render, maxcol;
  ;
