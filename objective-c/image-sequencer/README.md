Image Grouping
============

This class (MicroeventManager) handles grouping of photos together based on 2 different requirements:

 - An 'event' is 2 or more photos taken within 30 minutes of eachother
 - A 'wiggle' is a group of photos that are visually similar to eachother

A wiggle is created by analyzing the LAB colorspace of each photo. The server is responsible for
this analysis (not me) and then sends the client (me) a 192 byte struct of signed chars which are
values in Lab colorspace of the form [L a b L a b ...] for each photo. I (the client) parse each matrix
to determine which (if any) photos are similar. I determine the differences between
photos by calculating the square root of the sum of the squared distances between each corresponding
value in the matrix. If the difference is <= the threshold (200) I can reasonably assume these photos
are similar enough to create a Wiggle (aka Animated GIF).

The link below is a demo of the 'events' and 'wiggles' this code creates

<a href="http://vimeo.com/73715103" target="_blank"><img src="https://github.com/ehunter/github.io/blob/master/images/wiggles_demo.jpg?raw=true" 
alt="IMAGE ALT TEXT HERE" width="750" height="562" border="10" /></a>