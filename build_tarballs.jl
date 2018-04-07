using BinaryBuilder

# Collection of sources required to build bz2
sources = [
    "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz" =>
    "a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bzip2-1.0.6/

# Welp, auto-patching an include because otherwise win32/64 bzip2 won't cross-compile
sed -i 's/sys\\stat\.h/sys\/stat\.h/g' bzip2.c

# Override stubborn makevars
CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
OBJS="blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o"
make CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS}" LDFLAGS=$LDFLAGS -j${nproc} $OBJS
make CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS}" LDFLAGS=$LDFLAGS PREFIX=${prefix} install

# Build dynamic library
if [[ "${target}" == *-darwin* ]]; then
    $CC -shared -o libbz2.1.0.6.dylib $OBJS
    ln -s libbz2.1.0.dylib libbz2.1.0.6.dylib
    mv libbz2*.dylib ${prefix}/lib/
elif [[ "${target}" == *-mingw* ]]; then
    $CC -shared -o libbz2.dll $OBJS
    mv libbz2.dll ${prefix}/bin/
else
    $CC -shared -Wl,-soname -Wl,libbz2.so.1.0 -o libbz2.so.1.0.6
    ln -s libbz2.so.1.0 libbz2.so.1.0.6
    mv libbz2.so* ${prefix}/lib/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [
    Windows(:i686),
    Windows(:x86_64),
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc),
    Linux(:powerpc64le, :glibc),
    MacOS()
]

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix,"libbz2", :libbzip2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

build_tarballs(ARGS, "Bzip2", sources, script, platforms, products, dependencies)
