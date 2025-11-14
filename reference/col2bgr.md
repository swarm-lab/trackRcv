# Color to BGR Conversion

R color to BRG (blue/green/red) conversion.

## Usage

``` r
col2bgr(col, alpha = FALSE)
```

## Arguments

- col:

  Vector of any of the three kinds of R color specifications, i.e.,
  either a color name (as listed by
  [`colors`](https://rdrr.io/r/grDevices/colors.html)()), a hexadecimal
  string of the form "`#rrggbb`" or "`#rrggbbaa`" (see
  [`rgb`](https://rdrr.io/r/grDevices/rgb.html)), or a positive integer
  `i` meaning
  [`palette`](https://rdrr.io/r/grDevices/palette.html)`()[i]`.

- alpha:

  Logical value indicating whether the alpha channel (opacity) values
  should be returned.

## Value

An integer matrix with three or four (for `alpha = TRUE`) rows and
number of columns the length of `col`. If col has names these are used
as the column names of the return value.

## Details

[`NA`](https://rdrr.io/r/base/NA.html) (as integer or character) and
"NA" mean transparent.

Values of `col` not of one of these types are coerced: real vectors are
coerced to integer and other types to character. (factors are coerced to
character: in all other cases the class is ignored when doing the
coercion.)

Zero and negative values of `col` are an error.

## See also

[`col2rgb`](https://rdrr.io/r/grDevices/col2rgb.html),
[`rgb`](https://rdrr.io/r/grDevices/rgb.html),
[`palette`](https://rdrr.io/r/grDevices/palette.html)

## Author

Simon Garnier, <garnier@njit.edu>
