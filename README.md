
# trackRcv <a href="https://swarm-lab.github.io/trackRcv/"><img src="man/figures/logo.png" align="right" height="138" alt="trackRcv website" /></a>

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/trackRcv)](https://CRAN.R-project.org/package=trackRcv)
[![R-CMD-check](https://github.com/swarm-lab/trackRcv/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/swarm-lab/trackRcv/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/swarm-lab/trackRcv/graph/badge.svg)](https://app.codecov.io/gh/swarm-lab/trackRcv)
[![test-coverage](https://github.com/swarm-lab/trackRcv/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/swarm-lab/trackRcv/actions/workflows/test-coverage.yaml)
<!-- badges: end -->

## Description 

trackRcv is an object tracker for R based on Python [OpenCV](https://opencv.org/). 
It provides an easy-to-use (or so I think) graphical interface allowing users 
to perform multi-object video tracking in a range of conditions while 
maintaining individual identities.

trackRcv uses background subtraction to segment objects in a video. A background 
image can be provided by the user or can be computed by trackRcv automatically 
in most situations. Overlapping objects are then separated using cross-entropy 
clustering, an automated classification method that provides good computing 
performance while being able to handle various types of object shapes (see 
[the CEC package for R](https://swarm-lab.github.io/cec/) for more information 
on cross-entropy clustering). Most of the tracking parameters can be 
automatically estimated by trackRcv or can be set manually by the user. 

trackRcv also allows users to exclude parts of the image by using masks that can 
be easily created and customized directly within the app. 

Finally, trackRcv provides several convenience apps to correct common errors 
that occurs during video recording, to manually inspect and fix tracking errors, 
and to export publication-ready videos showing the moving objects with their 
track overlaid on top of them. 

---

## Quick start guides

+ [1. Installing trackRcv](https://swarm-lab.github.io/trackRcv/articles/z1_installing_trackRcv.html)
+ More to come...

---

## FAQ

**How does trackRcv compare to other video tracking solutions? Did we really need another one?**

trackRcv belongs to the category of the 'classical' tracking programs, similar 
in spirit to tracking software such as [`Ctrax`](http://ctrax.sourceforge.net/), 
[`tracktor`](https://github.com/vivekhsridhar/tracktor), and the sadly defunct
[`SwisTrack`](https://en.wikibooks.org/wiki/SwisTrack). It relies on good ol' 
fashion image processing, robust cross-entropy clustering, and simple, yet 
efficient, assignment algorithms (the Hungarian method in this case). trackRcv 
does not use any fancy machine learning methods. The downside is that trackRcv's 
tracking reliability may be inferior to more advanced software; the upside is 
that it does not require a beast of a computer to run. 

If trackRcv is not capable of tracking objects in your videos with the accuracy
that you require, you can try its 
[YOLO](https://github.com/ultralytics/ultralytics)-based AI counterpart, 
[trackRai](https://swarm-lab.github.io/trackRai)

-- 

**Will something break? Can I use trackRcv in 'production' mode?** 

Something will definitely break. This is mostly a one-person operation and I 
cannot promise that I have fully tested every single scenario that could 
challenge trackRcv. This being said, it will work fine in most cases and is 
certainly usable for most tracking projects. If you run into an issue, please 
report it at: https://github.com/swarm-lab/trackRcv/issues.

--

**How can I help?**

trackRcv is an open-source project, meaning that you can freely modify its code
and implement new functionalities. If you have coding skills, you are more than 
welcome to contribute new code or code improvement by submitting pull requests 
on the GitHub repository of the project at: https://github.com/swarm-lab/trackRcv. 
I will do my best to review and integrate them quickly. 

If you do not feel like contributing code, you can also help by submitting bug 
reports and feature requests using the issue tracker on the GitHub repository of 
the project at: https://github.com/swarm-lab/trackRcv/issues. These are extremely 
helpful to catch and correct errors in the code, and to guide the development of 
trackRcv by integrating functionalities requested by the community. 
