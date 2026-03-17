# OCTA

OCT Analysis.  Based on prior MATLAB work by Ivo Foelmi.

TODO: write a proper README

## SETUP
  requires python 3.10 or higher (tested on 3.10.5)
  
  in the root folder, run `pip install -r requirements.txt`
  
  ...
  
  and that's it

## OPTIONS
  

## RUNNING
  To run the analysis, just run `python octa.py options_filename` from root.  If
  a file doesn't exist, you should get an error, but this hasn't been tested
  rigorously.  There are no prompts: to modify the size of the images being
  calculated, modify `io_manager.py` directly, specifically the line [linked
  here](https://github.com/Checkmate50/octa/blob/main/src/io_manager.py#L110)

  All results are written to the folder specified by the options file.
  Literally all the results.  The CSV is written last, and only has the mean
  thickness calculation for now.  Note that this exactly matched the MATLAB code
  on my machine with the size values provided (within floating-point error of
  course, around a 1e-8 decimal error it looked like).
