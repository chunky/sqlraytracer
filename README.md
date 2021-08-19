# A Pure SQL Raytracer

Everyone writes a raytracer sooner or later. This is mine.

## Usage

```shell
sh create.sh
```

The shell script contains host/database/user/pass/etc. There are
no exotic needs other than "postgres, like version 10 and up or
something"

For what it's worth, I created mine thus on my ubuntu desktop:
```shell
sudo su - postgres
createuser --pwprompt raytracer
createdb -O raytracer raytracer
```

## Database

This is implemented in pure SQL. It doesn't do anything like CREATE
FUNCTION or other nonportables.

At the same time, there are some not-entirely-common features of SQL
that it needs:

* JOIN LATERAL
* PARTITION BY inside of a RECURSIVE CTE
* Math functions like SIN()

So although I started developing this in SQLite, I ended up leaning
on PostgreSQL. As I write this, it works in postgres and hasn't been
tested in anything else.

## Standing on the Necks of Giants

Two years before I wrote this "The most advanced MySQL raytracer on the
market right now" did the rounds on social media:
https://www.pouet.net/prod.php?which=83222

I had a few things in mind that I wanted to do differently [worse?]:

* Demoscene is an artform. I'm not golfing, this isn't minified
* Not a single query; that can be done with CTEs, but ehhhhhhhh
* Animation as an endgame
* Mainly, I'm just buggering around with the wrong tool for the job

## Interesting Implementation Pieces

Such as it is, I did find myself solving some problems in interesting
ways.

### JOIN LATERAL

JOIN LATERAL is a way to do a correlated subquery in a JOIN, instead of
just in a WHERE clause. I use this as a way to hoist calculations and
do many of them only once.

### Diffuse Scattering

This requires sampling a uniform sphere. I generate a lot of random
samples ahead of time [sample with rejection -> scale points to sphere
surface], and number them.

Figuring out a way to join each ray to a single random row from these
precalculated scatters was weird; can't just join to RANDOM() because
every ray got joined to the same, random, scatter. Can't just select
with a typical calculation on a normal because that leads to stripes
in the picture.  So, instead, I schlep out a later few decimals of one
dimension of a normal, then join to that. It's "random" but also
unique-enough-per-ray.

### Recursive CTEs

Raytracing very naturally tracks how recursive CTEs work. One of the
things I ran into was a clean way to identify which ray is the one to
account for. Using a window function ordering by intercept (t) worked
well. Every iteration, this query intersects a ray with *everything*
in front of it and does all of the associated calculations, but then in
the WHERE clause will reject everything except the thing the ray
actually hit.

Also, there's something really beautiful about the simplicity of the
core of the final rollup [edited for clarity]:
```sql
 SELECT img_x, img_y,
         SUM(POW(color_mult * ray_col_r/samples_per_px, gamma)) col_r,
         SUM(POW(color_mult * ray_col_g/samples_per_px, gamma)) col_g,
         SUM(POW(color_mult * ray_col_b/samples_per_px, gamma)) col_b
    FROM rays
     WHERE ray_col_r IS NOT NULL
    GROUP BY img_y, img_x
```

## References

Most of this is built following the "Ray Tracing in One Weekend"
series: https://raytracing.github.io/ , then making allowances for
the deliberately obtuse way I'm coding it.


Gary <chunky@icculus.org>
