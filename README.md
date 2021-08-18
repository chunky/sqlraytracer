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

## References

Most of this is built following the "Ray Tracing in One Weekend"
series: https://raytracing.github.io/ , then making allowances for
the deliberately obtuse way I'm coding it.


Gary <chunky@icculus.org>
