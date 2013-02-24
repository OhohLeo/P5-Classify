P5-Classify
=============

Optimised Collection Manager

03/02/2013 Leo
* Classify : set up log (great, info, warn, critic) centralised process
* Console : set up asynchronous console to accept/refuse classified data.
* Import : correct name of the files (bad extension)
* classify.pl : we can now set up proprieties for each collections
* Cinema : we handle movie subtitles & find for matching movies
* Base : add generic log methods

26/01/2013 Leo
* Model : we replace 'Objects' by 'Model' : simple hash manager.
* Cinema : first collection set up

16/12/2012 Leo
* Import::Files : improve asynchronous research but it is not perfect yet...

19/11/2012 Leo
* Import::Files : create first asynchronous directories reader & display

17/11/2012 Leo
* classify.pl : set up console commands to test websites & imports
*               create 'info' commands to display detailed informations

11/11/2012 Leo
* classify.pl : Set up console commands to create collections
* Collection::Cinema : Set up 1st Collection
* Import::Files Set up asynchronous import files
* Classify : Store collections data thanks to Storable
* Display : method to create new windows
* Web::IMDB : handle description, country, genre & poster & unit tests

17/10/2012 Leo
* Set some objects : Character, Star, Movie & Image
* Set up Web/IMDB + unit tests
* Moo simplifications

10/10/2012 Leo
* Use Moo Minimal Object Manager
* 1st Window display method
* 1st IMDB asynchronous request
* Rename Project

06/10/2012 Leo
* Set up dzil environment
* Set anyevent, gtk & translation tools
