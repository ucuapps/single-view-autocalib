For a symmetric matrix A, A(:) (full "vectorization") contains more 
information than is strictly necessary, since the matrix is completely 
determined by the symmetry together with the lower triangular portion, 
that is, the n(n+1)/2 entries on and below the main diagonal. The 
half-vectorization, built as following with the package:
  > A(itril(size(A))), 
of a symmetric n×n matrix A is the n(n+1)/2 × 1 column vector obtained by 
"vectorizing" only the lower triangular part of A.

This package provides functions for conveniently indexing the triangular
parts (both lower and upper) parst as well as the diagonals of the matrix.

It also provides the so called Duplication and Elimination matrices which
is used to convert between full and half-vectorization of the matrix.

See: http://en.wikipedia.org/wiki/Vectorization_(mathematics)

Please take a look at the script testprog.m to get an idea how the package
works.
