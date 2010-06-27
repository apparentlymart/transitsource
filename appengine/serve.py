
from os import environ
from cgi import parse_qs

if environ["REQUEST_METHOD"] != "GET":
    print "Status: 405 Method Not Allowed\n\nMethod not allowed"
    exit()

path = environ["PATH_INFO"]
if "QUERY_STRING" in environ:
    query_args = parse_qs(environ["QUERY_STRING"])


jsonp_callback = None
if path.endswith(".js"):
    path = path + "on"
    if "callback" in query_args:
        jsonp_callback = query_args["callback"][0]
    else:
        jsonp_callback = "callback"
    if "callback" in query_args:
        del query_args["callback"]
    if "_" in query_args:
        del query_args["_"]

if len(query_args.keys()) > 0:
    print "Status: 400 Bad Request\n\nInvalid query string"
    exit()

f = open("data"+path)

print "Access-Control-Allow-Origin: *"

if jsonp_callback is not None:
    print "Content-Type: text/javascript\n"
    print jsonp_callback+"("
else:
    print "Content-Type: application/json\n"

print f.read()

if jsonp_callback is not None:
    print ");"






