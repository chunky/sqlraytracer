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
  rot_x REAL NOT NULL, rot_y REAL NOT NULL, rot_z REAL NOT NULL,
  fov_rad_x REAL NOT NULL, fov_rad_y REAL NOT NULL,
  max_ray_depth INTEGER);
INSERT INTO camera (x, y, z, rot_x, rot_y, rot_z, fov_rad_x, fov_rad_y, max_ray_depth)
  VALUES (0.0, 0.0, -40.0, 0.0, 0.0, 0.0, PI()/2.0, PI()/2.0, 4);

DROP TABLE IF EXISTS img;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL);
INSERT INTO img (res_x, res_y) VALUES (350, 350);

DROP VIEW IF EXISTS rays;
CREATE VIEW rays AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     rs(img_x, img_y, depth, max_ray_depth, ray_col,
          x1, y1, z1, x2, y2, z2, -- Two points on the ray
          dir_x, dir_y, dir_z, dir_lensquared, ray_len, hit_light, t) AS
        -- Send out initial set of rays from camera
         (SELECT xs.u, ys.v, 0, max_ray_depth, NULL, c.x, c.y, c.z,
                 c.x + SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x), c.y + SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y), z + 1.0,
                 SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x), SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y), 1.0,
                 SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x)*SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x)
                        + SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y)*SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y)
                        + 1.0,
                 0.0, 0, 0
              FROM camera c, img, xs, ys
        UNION ALL
         -- Collide all rays with spheres
          SELECT img_x, img_y, depth+1, max_ray_depth, sphere_col,
                 -- x1, y1, z1
                 x1+dir_x*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 y1+dir_y*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 z1+dir_z*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 -- x2, y2, z2
                 2*cx - x1 + dir_x + 3 * dir_x * (-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 2*cy - y1 + dir_y + 3 * dir_y * (-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 2*cz - z1 + dir_z + 3 * dir_z * (-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared),
                 -- dir_x, dir_y, dir_z
                 -dir_x+2*(cx-x1+dir_x*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared)),
                 -dir_y+2*(cy-y1+dir_y*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared)),
                 -dir_z+2*(cz-z1+dir_z*(-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared)),
                 dir_lensquared,
                 SQRT((cx-x1)*(cx-x1) + (cy-y1)*(cy-y1) + (cz-z1)*(cz-z1)), -- distance to center. fixme should be distance to intersection
                 s.is_light,
                     -((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                       -SQRT(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                      - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared


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
           FROM rs
           INNER JOIN sphere s ON
               -- https://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
               -- d=len( circ_center-p1 X circ_center-p2) / len(dir_x, dir_y, dir_z)
               -- This is "does this ray collide"
             s.radius2 >
                  ((((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2))*((cy-y1)*(cz-z2)-(cz-z1)*(cy-y2)) +
                    ((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2))*((cz-z1)*(cx-x2)-(cx-x1)*(cz-z2)) +
                    ((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))*((cx-x1)*(cy-y2)-(cy-y1)*(cx-x2))) /
                (dir_x*dir_x + dir_y*dir_y + dir_z*dir_z))
              WHERE depth<max_ray_depth AND 0=hit_light)
   SELECT *, ROW_NUMBER() OVER (PARTITION BY img_x, img_y, depth ORDER BY ray_len ASC) AS ray_len_idx FROM rs;

DROP VIEW IF EXISTS do_render;
CREATE VIEW do_render AS
 SELECT A.img_x, A.img_y, COALESCE(MAX(A.ray_col * 1.0/A.depth),
       0.5+0.5*(A.dir_y/(SQRT(A.dir_x*A.dir_x + A.dir_y*A.dir_y + A.dir_z*A.dir_z)))) AS col
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
    SELECT CAST(col*mc AS INTEGER) || ' ' || CAST(col*mc AS INTEGER) || ' ' || CAST(col*mc AS INTEGER)
      FROM do_render, maxcol;
  ;
