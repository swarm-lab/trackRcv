# trackRcv

## Description

trackRcv is an object tracker for R based on Python
[OpenCV](https://opencv.org/). It provides easy-to-use (or so I think)
apps for performing multi-object video tracking in a range of conditions
while maintaining individual identities. trackRcv also provides
convenience apps to correct common errors that occurs during tracking,
and to export publication-ready videos showing the moving objects with
their track overlaid on top of them.

trackRcv uses traditional computer vision techniques to segment and
track objects in a video. Object separation is done using cross-entropy
clustering, an automated classification method that provides good
computing performance while being able to handle various types of object
shapes (see [the CEC package for R](https://swarm-lab.github.io/cec/)
for more information on cross-entropy clustering). For more advanced
segmentation and tracking based on deep learning approaches, you can try
my [YOLO11](https://docs.ultralytics.com/models/yolo11/)-based
[trackRai](https://swarm-lab.github.io/trackRai) package instead (a
powerful CUDA-enabled NVIDIA graphics is recommended in that case).

------------------------------------------------------------------------

## Installation

You can install the development version of trackRcv from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("swarm-lab/trackRcv")
```

------------------------------------------------------------------------

## User guides

- [1. Installing
  trackRcv](https://swarm-lab.github.io/trackRcv/articles/z1_installing_trackRcv.html)
- [2. Tracking
  objects](https://swarm-lab.github.io/trackRcv/articles/z2_tracking_objects.html)
- [3. Fixing
  tracks](https://swarm-lab.github.io/trackRcv/articles/z3_fixing_tracks.html)
- [4. Visualizing
  tracks](https://swarm-lab.github.io/trackRcv/articles/z4_visualizing_tracks.html)

------------------------------------------------------------------------

## FAQ

**How does trackRcv compare to other video tracking solutions? Did we
really need another one?**

trackRcv belongs to the category of the ‘classical’ tracking programs,
similar in spirit to tracking software such as
[`Ctrax`](http://ctrax.sourceforge.net/),
[`tracktor`](https://github.com/vivekhsridhar/tracktor), and the sadly
defunct [`SwisTrack`](https://en.wikibooks.org/wiki/SwisTrack). It
relies on good ol’ fashion image processing, robust cross-entropy
clustering, and simple, yet efficient, assignment algorithms (the
Hungarian method in this case). trackRcv does not use any fancy machine
learning methods. The downside is that trackRcv’s tracking reliability
may be inferior to more advanced software; the upside is that it does
not require a beast of a computer to run.

If trackRcv is not capable of tracking objects in your videos with the
accuracy that you require, you can try its
[YOLO](https://github.com/ultralytics/ultralytics)-based AI counterpart,
[trackRai](https://swarm-lab.github.io/trackRai)

–

**Will something break? Can I use trackRcv in ‘production’ mode?**

Something will definitely break. This is mostly a one-person operation
and I cannot promise that I have fully tested every single scenario that
could challenge trackRcv. This being said, it will work fine in most
cases and is certainly usable for most tracking projects. If you run
into an issue, please report it at:
<https://github.com/swarm-lab/trackRcv/issues>.

–

**How can I help?**

trackRcv is an open-source project, meaning that you can freely modify
its code and implement new functionalities. If you have coding skills,
you are more than welcome to contribute new code or code improvement by
submitting pull requests on the GitHub repository of the project at:
<https://github.com/swarm-lab/trackRcv>. I will do my best to review and
integrate them quickly.

If you do not feel like contributing code, you can also help by
submitting bug reports and feature requests using the issue tracker on
the GitHub repository of the project at:
<https://github.com/swarm-lab/trackRcv/issues>. These are extremely
helpful to catch and correct errors in the code, and to guide the
development of trackRcv by integrating functionalities requested by the
community.
