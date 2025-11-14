# Codec Name to FOURCC Code

`fourcc` translates the 4-character name of a video codec into its
corresponding [FOURCC](https://www.fourcc.org/codecs.php) code.

## Usage

``` r
fourcc(x)
```

## Arguments

- x:

  A 4-element character chain corresponding to the name of a valid video
  codec. A list of valid codec names can be found at this archived page
  of the fourcc site <https://www.fourcc.org/codecs.php>.

## Value

An integer value corresponding to the FOURCC code of the video codec.

## Author

Simon Garnier, <garnier@njit.edu>
