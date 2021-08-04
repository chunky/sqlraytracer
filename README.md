# A Pure SQL RayTracer

Everyone writes a raytracer sooner or later. This is mine.

## Database

Uses SQLite version >= 3.35, which must be compiled with 
```-DSQLITE_ENABLE_MATH_FUNCTIONS```

On ubuntu, if you download the latest SQLite amalgam:
```shell
gcc -o sqlite3 -DSQLITE_ENABLE_MATH_FUNCTIONS shell.c sqlite3.c \
    -ldl -lpthread  -lm
```

## References

Most of this is built following the "Ray Tracing in One Weekend"
series: https://raytracing.github.io/ , then making allowances for
the deliberately obtuse way I'm coding it.


Gary <chunky@icculus.org>
