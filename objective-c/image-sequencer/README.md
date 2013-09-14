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

###Demo of the 'events' and 'wiggles' this code creates
<iframe src="//player.vimeo.com/video/73715103" width="500" height="758" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> <p><a href="http://vimeo.com/73715103">Woven Wiggles</a> from <a href="http://vimeo.com/user2773262">Erik Hunter</a> on <a href="https://vimeo.com">Vimeo</a>.</p>