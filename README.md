# A Pure SQL RayTracer

Everyone writes a raytracer sooner or later. This is mine.

## Database

This is implemented in pure SQL. It doesn't do anything like CREATE
FUNCTION or other nonportable designs.

At the same time, there are some not-100%-common features of SQL that
it needs:

* JOIN LATERAL
* PARTITION BY inside of a RECURSIVE CTE
* Math functions like sin()

So although I started developing this in SQLite, I ended up leaning
on PostgreSQL. As I write this, it works in postgres and hasn't been
tested in anything else.

## References

Most of this is built following the "Ray Tracing in One Weekend"
series: https://raytracing.github.io/ , then making allowances for
the deliberately obtuse way I'm coding it.


Gary <chunky@icculus.org>
