DROP TABLE IF EXISTS material CASCADE;
CREATE TABLE material (materialid SERIAL PRIMARY KEY, name TEXT,
  mat_col_r DOUBLE PRECISION NOT NULL, mat_col_g DOUBLE PRECISION NOT NULL, mat_col_b DOUBLE PRECISION NOT NULL,
  is_light BOOLEAN NOT NULL, is_metal BOOLEAN NOT NULL, shade_normal BOOLEAN NOT NULL, is_mirror BOOLEAN NOT NULL);
INSERT INTO material (name, mat_col_r, mat_col_g, mat_col_b, is_light, is_metal, shade_normal, is_mirror) VALUES
    ('dark', 0.1, 0.1, 0.1, FALSE, TRUE, FALSE, FALSE),
    ('red', 0.95, 0.0, 0.0, FALSE, TRUE, FALSE, FALSE),
    ('green', 0.0, 0.95, 0.0, FALSE, TRUE, FALSE, FALSE),
    ('blue', 0.0, 0.0, 0.95, FALSE, TRUE, TRUE, FALSE),
    ('bright', 1.0, 1.0, 1.0, FALSE, TRUE, TRUE, FALSE),
    ('mirror', 0.0, 0.0, 0.0, FALSE, FALSE, FALSE, TRUE)
;

DROP TABLE IF EXISTS sphere CASCADE;
CREATE TABLE sphere (sphereid SERIAL,
  cx DOUBLE PRECISION NOT NULL, cy DOUBLE PRECISION NOT NULL, cz DOUBLE PRECISION NOT NULL,
  radius DOUBLE PRECISION NOT NULL, radius2 DOUBLE PRECISION, materialid INTEGER NOT NULL REFERENCES material(materialid));
INSERT INTO sphere (cx, cy, cz, radius, materialid) VALUES
    (9, 9, -10, 5, (SELECT materialid FROM material WHERE name='dark')),
    (-5, 7, 17, 7, (SELECT materialid FROM material WHERE name='red')),
    (15, -15, -1, 4, (SELECT materialid FROM material WHERE name='green')),
    (-2, -3, 8, 10, (SELECT materialid FROM material WHERE name='blue')),
    (-15, -3, -15, 2, (SELECT materialid FROM material WHERE name='bright')),
    (0, -950, 0, 1000, (SELECT materialid FROM material WHERE name='mirror'))
;
UPDATE sphere SET radius2 = radius*radius WHERE radius2 IS NULL;

DROP TABLE IF EXISTS camera CASCADE;
CREATE TABLE camera (cameraid INTEGER PRIMARY KEY,
  x DOUBLE PRECISION NOT NULL, y DOUBLE PRECISION NOT NULL, z DOUBLE PRECISION NOT NULL,
  rot_x DOUBLE PRECISION NOT NULL, rot_y DOUBLE PRECISION NOT NULL, rot_z DOUBLE PRECISION NOT NULL,
  fov_rad_x DOUBLE PRECISION NOT NULL, fov_rad_y DOUBLE PRECISION NOT NULL,
  max_ray_depth INTEGER NOT NULL, samples_per_px INTEGER NOT NULL);
INSERT INTO camera (cameraid, x, y, z, rot_x, rot_y, rot_z, fov_rad_x, fov_rad_y, max_ray_depth, samples_per_px)
  VALUES (1.0, 0.0, 0.0, -120.0, 0.0, 0.0, 0.0, PI()/2.0, PI()/2.0, 6, 2);

DROP TABLE IF EXISTS img CASCADE;
CREATE TABLE img (res_x INTEGER NOT NULL, res_y INTEGER NOT NULL, gamma DOUBLE PRECISION);
    INSERT INTO img (res_x, res_y, gamma) VALUES (650, 650, 1.5);

