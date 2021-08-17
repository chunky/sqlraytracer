-- Skipped bits:
--   "Front faces vs back faces"
DROP VIEW IF EXISTS rays CASCADE;
CREATE VIEW rays AS
    WITH RECURSIVE xs AS (SELECT 0 AS u, 0.0 AS img_frac_x UNION ALL SELECT u+1, (u+1.0)/img.res_x FROM xs, img WHERE xs.u<img.res_x-1),
     ys AS (SELECT 0 AS v, 0.0 AS img_frac_y UNION ALL SELECT v+1, (v+1.0)/img.res_y FROM ys, img WHERE ys.v<img.res_y-1),
     px_sample_n(px_sample_n) AS (SELECT 1 UNION ALL SELECT px_sample_n+1 FROM px_sample_n, camera WHERE px_sample_n<camera.samples_per_px),
     rs(img_x, img_y, depth, max_ray_depth, samples_per_px, px_sample_n, color_mult,
          ray_col_r, ray_col_g, ray_col_b,
          x1, y1, z1,
          dir_x, dir_y, dir_z,
          dir_lensquared,
          ray_len, stop_tracing, ray_len_idx) AS
        -- Send out initial set of rays from camera
         (SELECT xs.u, ys.v, -1, max_ray_depth, samples_per_px, px_sample_n, 1.0,
                CAST(NULL AS DOUBLE PRECISION), CAST(NULL AS DOUBLE PRECISION), CAST(NULL AS DOUBLE PRECISION),
                 c.x, c.y, c.z,
                 SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x) + 0.5 * (RANDOM()-0.5) * (fov_rad_x/res_x),
                 SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y) + 0.5 * (RANDOM()-0.5) * (fov_rad_y/res_y),
                 CAST(1.0 AS DOUBLE PRECISION),
                 SQRT(SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x)*SIN(-(fov_rad_x/2.0)+img_frac_x*fov_rad_x) +
                      SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y)*SIN(-(fov_rad_y/2.0)+img_frac_y*fov_rad_y) + 1.0),
                 CAST(1.0 AS DOUBLE PRECISION), CAST(0 AS BOOLEAN), CAST(1 AS BIGINT)
              FROM camera c, img, xs, ys, px_sample_n
        UNION ALL
         -- Collide all rays with spheres
          SELECT img_x, img_y, depth+1, max_ray_depth, samples_per_px, px_sample_n,
                 (CASE WHEN is_mirror THEN 1.0 ELSE 0.5 END)*color_mult,
                 CASE WHEN discrim>0 THEN (CASE
                                                WHEN shade_normal THEN mat_col_r*(1+norm_x/norm_len)
                                                WHEN is_mirror THEN NULL
                                                ELSE mat_col_r
                                           END)
                     ELSE 1.0-(0.5*((dir_y/SQRT(dir_lensquared)+1.0)))+0.2*(0.5*((dir_y/SQRT(dir_lensquared)+1.0))) END,
                 CASE WHEN discrim>0 THEN (CASE
                                                WHEN shade_normal THEN mat_col_g*(1+norm_y/norm_len)
                                                WHEN is_mirror THEN NULL
                                                ELSE mat_col_g
                                           END)
                     ELSE 1.0-(0.5*((dir_y/SQRT(dir_lensquared)+1.0)))+0.3*(0.5*((dir_y/SQRT(dir_lensquared)+1.0))) END,
                 CASE WHEN discrim>0 THEN (CASE
                                                WHEN shade_normal THEN mat_col_b*(1+norm_y/norm_len)
                                                WHEN is_mirror THEN NULL
                                                ELSE mat_col_b
                                           END)
                     ELSE 1.0-(0.5*((dir_y/SQRT(dir_lensquared)+1.0)))+1.0*(0.5*((dir_y/SQRT(dir_lensquared)+1.0))) END,
                 -- x1, y1, z1
                 hit_x, hit_y, hit_z,
                 -- dir_x, dir_y, dir_z
                 norm_x/norm_len, norm_y/norm_len, norm_z/norm_len, CAST(1.0 AS DOUBLE PRECISION),
                 -- distance to center. fixme should be distance to intersection
                 t * SQRT(dir_lensquared),
                 discrim IS NULL OR is_light, ROW_NUMBER() OVER (PARTITION BY img_x, img_y, depth+1, px_sample_n
                                                          ORDER BY t)
           FROM rs
           LEFT JOIN LATERAL
               (SELECT s.*, ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                                - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2) discrim,
                       (-((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                        -SQRT(ABS(((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z) * ((x1-cx)*dir_x + (y1-cy)*dir_y + (z1-cz)*dir_z)
                            - dir_lensquared * ((x1-cx)*(x1-cx) + (y1-cy)*(y1-cy) + (z1-cz)*(z1-cz) - radius2)) / dir_lensquared)) t
                         FROM sphere s
                       ) hit_sphere ON discrim>0 AND t>0
           LEFT JOIN LATERAL
               (SELECT x1+dir_x*t AS hit_x, y1+dir_y*t AS hit_y, z1+dir_z*t AS hit_z,
                       x1+dir_x*t-cx AS norm_x, y1+dir_y*t-cy AS norm_y, z1+dir_z*t-cz AS norm_z,
                       SQRT((x1+dir_x*t-cx)*(x1+dir_x*t-cx)+(y1+dir_y*t-cy)*(y1+dir_y*t-cy)+(z1+dir_z*t-cz)*(z1+dir_z*t-cz)) AS norm_len
               ) sphere_normal ON discrim>0 AND t>0
           LEFT JOIN material ON material.materialid=hit_sphere.materialid
              WHERE depth<max_ray_depth AND NOT stop_tracing AND ray_len_idx=1)
   SELECT * FROM rs WHERE ray_len_idx=1;

--SELECT * FROM rays WHERE img_x=
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
 SELECT A.img_x, -A.img_y,
--          SUM(A.ray_col_r / (A.samples_per_px*POW(2, A.depth))) col_r,
--          SUM(A.ray_col_g / (A.samples_per_px*POW(2, A.depth))) col_g,
--          SUM(A.ray_col_b / (A.samples_per_px*POW(2, A.depth))) col_b
         GREATEST(0.0, LEAST(1.0, SUM(POW(A.color_mult * A.ray_col_r/A.samples_per_px, gamma)))) col_r,
         GREATEST(0.0, LEAST(1.0, SUM(POW(A.color_mult * A.ray_col_g/A.samples_per_px, gamma)))) col_g,
         GREATEST(0.0, LEAST(1.0, SUM(POW(A.color_mult * A.ray_col_b/A.samples_per_px, gamma)))) col_b

    FROM rays A, img
     WHERE A.ray_col_r IS NOT NULL AND A.depth>=0
        --LEFT JOIN rays B ON A.img_x=B.img_x AND A.img_y=B.img_y AND A.ray_len_idx=1 AND A.depth=B.depth-1
    GROUP BY -A.img_y, A.img_x
    ORDER BY -A.img_y, A.img_x;

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

-- SELECT * FROM rays WHERE img_x=2 AND img_y=2;