#!/bin/env python

#
# To Run:
# PWD=../metadata
# python tools/blaster.py
#

from os.path import isdir
from json import JSONEncoder
from string import capitalize
from jinja2 import Environment, PackageLoader

import csv
import urllib2

def unicode_csv_reader(utf8_data, dialect=csv.excel, **kwargs):
    csv_reader = csv.reader(utf8_data, dialect=dialect, **kwargs)
    for row in csv_reader:
        yield [unicode(cell, 'utf-8') for cell in row]

env = Environment(loader=PackageLoader('blaster', 'templates'))

def tmpl_urlencode(value):
    return urllib2.quote(value)
env.filters['urlencode'] = tmpl_urlencode

def tmpl_jsonencode(value):
    return JSONEncoder().encode(value)
env.filters['jsonencode'] = tmpl_jsonencode


def get_listing_id(show):
    return 'litl_pbs_' + get_show_id(show)

def get_show_id(show):
    clean = show.replace('!', '').replace('\'', '').replace('&', '')
    clean = ''.join(capitalize(w) for w in clean.split(' '))
    return clean[0].lower() + clean[1:]

def clean_keywords(keywords):
    clean = keywords.strip()
    if not 'PBS' in clean:
        clean = 'PBS, ' + clean
    return clean

#  0 = [u'Show',
#  1 =  u'Launch Date',
#  2 =  u'GA/Kids',
#  3 =  u'Feed',
#  4 =  u'Assets (640x480, logo, background)',
#  5 =  u'Transparent Logo?',
#  6 =  u'Keywords',
#  7 =  u'Description',
#  8 =  u'summary',
#  9 =  u'"Go to web page"',
# 10 =  u'post launch fixes']
rows = unicode_csv_reader(open('tools/PBS%20Shows.csv', 'r'))
template = env.get_template('metadata.json')
for row in rows:
    listing_id = get_listing_id(row[0])
    dirname = listing_id
    if not isdir(dirname):
        print "Can't find %s dir, dumping into skipped/." % dirname
        dirname = 'skipped'

    fp = open('%s/metadata.json' % dirname, 'w')
    fp.write(template.render({
        'show': row[0],
        'listing_id': listing_id,
        'url': row[9],
        'summary': row[8],
        'description': row[7],
        'keywords': clean_keywords(row[6]),
        'show_id': get_show_id(row[0]),
        'type': row[2],
    }))
    fp.close()
