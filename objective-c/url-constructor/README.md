Utility Class  for constructing URL's
============

 This a utility class for constructing image URL's used throughout the app I work on called Woven.

 There are two types of URL's this class creates:

 -  A url from a hosted service (i.e. flickr) based on a set of available sizes the server gives us.
 - A 'pretzel' URL constructed from one the above URL's. 

Pretzel is the image resizing service we're using on the server.  The way pretzel works is the clients sends the service a custom image URL with a specific width and height. Pretzel returns a new image url at the exact size we requested. This class assists in the creation of those custom image URL's.