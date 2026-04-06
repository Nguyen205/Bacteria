# OCTA

This repository contains tooling for OCT Analysis, including various supporting
scripts to help with data cleaning.  The core OCT analysis tool is based on
prior MATLAB work by Ivo Foelmi.

Concretely, we include the following two scripts:
1. octa.py, which is used for running OCT analysis as described below
2. blackout.py, a utility script to help with data cleaning above a hand-drawn
   and fixed black line.  Note that blackout.py can be run using the same setup
   as octa.py, and takes files directly as arguments rather than an option file.
3. remove_artifacts.py, a utility script to help clean up images by setting pixels
   that are greater than 10 pixels away from their neighbor to be equal to their
   neighbor

## Contact

If you have major problems with the OCTA script or if this framework requires
light maintainance/bugfixing, please feel free to contact Dietrich Geisler with
questions.  They can be currently best reached at
dietrich.geisler@northwestern.edu, but you may need to check their website if
this email is out of date.

## Setup

OCTA requires installation of the [Python
interpreter](https://www.python.org/downloads/) version 3.10 or higher (and is
most recently tested on Python 3.10.5).
  
To install the Python library requirements, navigate to the root folder of this
project in command line / terminal and run `pip install -r requirements.txt`.
To validate that you installed the requirements correctly, you can run `python
octa.py`, which will error if there are any missing libraries.  Note that the
default behaviour of this script is to prompt you for additional command line
arguments, as [described below](#running-octa).

For documentation reasons, OCTA was tested with the following package versions:
* Pillow==10.0.1
* numpy==1.26.1
* toml==0.10.2

## Running OCTA

To run OCTA, run `python octa.py options_filename.toml` from the root folder of 
this project.  To help with demonstrating the behaviour of this tool, we provide
several example `.toml` options files in options/*.  Details on writing your own
options file (which is the primary mechanism to manipulate OCTA) are found in
the [Options](#options) section below.

For example, you may run:
```
python octa.py options/options_example.toml
```
To run OCT analysis on the image in examples/*.  The results of this analysis
are written (by default) to results/images, results/data.csv, and
results/log.csv.

## Options

OCTA runtime options (file inputs, mode selection details, output location, etc)
are all found in the TOML file provided as a command line argument as [described
above](#running-octa).  An exact list of all options (without description) can
be found in src/data/options.json.

The intended primary options to be used are described
options/options_example.toml.  We highly encourage you to copy this file rather
than editing it directly (unless you are developing OCTA further yourself) to
help future users of the OCTA script have a fixed example.  Note that the tags
included in the TOML file \[basics\] and \[locations\] are not optional.  Note
also that options tagged with (nullable) indicate these options can be skipped
by leaving them as "false", meaning that the given input is not included.

You can write as many option files as you would like, and option files are
intended to be maintained to make experiments easy to replicate.  Provided OCTA
itself is not adjusted, running OCTA with the same image files and the same
options file should always produce the same results.

## OCTA Format Details

OCTA expects between 2 and 4 folders containing .TIF images with the following
layouts as input:
1. gs files (required): raw OCT image files
2. gsm files (required): OCT image files with the membrane marked by a thin
   black line
3. bw files (optional): black-and-white files produced from running the initial
   image simplification passes in OCTA.  Primarily intended to improve
   performance, since you can rerun the second half of analysis again if needed
   with already-analyzed BW images
4. bwc files (optional): black-and-white with cutoff files produced after
   removing white pixels above the marked membrane line.  As with bw files,
   these are intended to be used to help with performance if needing to run
   later steps of the OCTA analysis.

OCTA writes out images in the following formats to the image_results folder
provided in the given TOML file:

1. bw and bwc, as described above
2. outl_folder_number.tif, which contains a bwc image with outliers removed.
   Details of the outlier removal algorithm can be found in image_mod.py under
   the calc_outliers function
3. outl2_folder_number.tif, which contains a visual illustration of the found
   membrane and removed points, where the green line indicates the membrane
   upper limit and the red dots indicate removed pixels.

Additionally, OCTA writes out a statistical summary to data.csv.  These numbers
vary in utility, and future authors of OCTA should consider pairing down these
columns after identifying the data most relevant to their use case.

Note that log.csv is not currently used, but has been used for debugging or for
providing summary information and is left in to be repurposed if needed.

## Code Outline

Internally, all OCTA code can be found in the src/ folder.  The general flow of
code is managed by octa.py itself, and the "interesting" computation primarily
involves manipulating the ImageData objects defined in src/image_data.py.

Images are stored as numpy arrays for performance, and programmers should use
caution when duplicating image arrays rather than manipulating images in-place.
Image manipulations and calculations are defined in image_mod.py and calc.py
respectively, which is in turn are driven by driver.py.  The order of these 
operations at a high-level is kept separate in octa.py to help with 
understanding flow, but keep in mind most driver operations are stateful, so the 
order of modifications in this flow is critical.

Finally, options are parsed in options.py, which is moderately involved due to
the number of options we aim to support.  This approach to options is a bit
clunky and overengineered, so if you aim to rework the repository, the options
manipulation is where I would suggest starting to make the code flow more
smoothly overall.

a file doesn't exist, you should get an error, but this hasn't been tested
rigorously.  There are no prompts: to modify the size of the images being
calculated, modify `io_manager.py` directly, specifically the line [linked
here](https://github.com/Checkmate50/octa/blob/main/src/io_manager.py#L110)

All results are written to the folder specified by the options file.
Literally all the results.  The CSV is written last, and only has the mean
thickness calculation for now.  Note that this exactly matched the MATLAB code
on my machine with the size values provided (within floating-point error of
course, around a 1e-8 decimal error it looked like).

Finally, note that blackout.py has a significant amount of duplicate logic to
the core octa.py library code.  As a practical matter, if you aim to extend
blackout.py or include more functionality, I would suggest considering
integrating this with the OCTA code and providing more options rather than
continuing to add more scripts.

### Design Note

The design and complexity of OCTA output is intended to be backwards compatible
with the reference MATLAB code.  If you are looking to improve OCTA, there are
many ways this pipeline could be simplified depending on use.  If maintaining
compatibility is desired, however, then the author recommends extending the
options file to add new features and to consider branching the flow of OCTA
rather than adding new passes on the end of the existing pipeline.