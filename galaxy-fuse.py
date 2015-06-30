#!/usr/bin/env python
"""
galaxy-fuse.py will mount Galaxy datasets for direct read access using FUSE.

To do this you will need your Galaxy API key, found by logging into Galaxy and
selecting the menu option User -> API Keys. You can mount your Galaxy datasets
using a command like

    python galaxy-fuse.py <api-key> &

This puts the galaxy-fuse process into the background. Galaxy Datasets will then
appear as read-only files, organised by History, under the directory galaxy_files.

galaxy-fuse was written by Dr David Powell and began life at
https://github.com/drpowell/galaxy-fuse .
"""
from errno import ENOENT
from stat import S_IFDIR, S_IFREG, S_IFLNK
from sys import argv, exit
import re
import time
import os
import argparse
import subprocess

from fuse import FUSE, FuseOSError, Operations, LoggingMixIn, fuse_get_context

from string import Template
import logging
DEBUG = os.environ.get('DEBUG', "False").lower() == 'true'
if DEBUG:
    logging.basicConfig(level=logging.DEBUG)
logging.getLogger("bioblend").setLevel(logging.CRITICAL)
log = logging.getLogger()

from bioblend import galaxy
from bioblend.galaxy import objects

with open('/etc/profile.d/galaxy.sh', 'r') as handle:
    logging.debug('PATH %s', os.environ['PATH'])
    for pair in handle:
        values = pair.strip().split('=')
        key = values[0]
        value = '='.join(values[1:])
        os.environ[key] = value
    logging.debug('PATH after loading env file %s', os.environ['PATH'])


def _get_ip():
    """Get IP address for the docker host
    """
    cmd_netstat = ['netstat','-nr']
    p1 = subprocess.Popen(cmd_netstat, stdout=subprocess.PIPE)
    cmd_grep = ['grep', '^0\.0\.0\.0']
    p2 = subprocess.Popen(cmd_grep, stdin=p1.stdout, stdout=subprocess.PIPE)
    cmd_awk = ['awk', '{ print $2 }']
    p3 = subprocess.Popen(cmd_awk, stdin=p2.stdout, stdout=subprocess.PIPE)
    galaxy_ip = p3.stdout.read().strip()
    log.debug('Host IP determined to be %s', galaxy_ip)
    return galaxy_ip


def _test_url(url, key, history_id):
    """Test the functionality of a given galaxy URL, to ensure we can connect
    on that address."""
    try:
        gi = objects.GalaxyInstance(url, key)
        gi.histories.get(history_id)
        log.debug('Galaxy URL %s is functional', url)
        return gi
    except Exception:
        return None


def get_galaxy_connection(history_id=None):
    """
        Given access to the configuration dict that galaxy passed us, we try and connect to galaxy's API.

        First we try connecting to galaxy directly, using an IP address given
        us by docker (since the galaxy host is the default gateway for docker).
        Using additional information collected by galaxy like the port it is
        running on and the application path, we build a galaxy URL and test our
        connection by attempting to get a history listing. This is done to
        avoid any nasty network configuration that a SysAdmin has placed
        between galaxy and us inside docker, like disabling API queries.

        If that fails, we failover to using the URL the user is accessing
        through. This will succeed where the previous connection fails under
        the conditions of REMOTE_USER and galaxy running under uWSGI.
    """
    history_id = history_id or os.environ['HISTORY_ID']
    key = os.environ['API_KEY']

    ### Customised/Raw galaxy_url ###
    galaxy_ip = _get_ip()
    # Substitute $DOCKER_HOST with real IP
    url = Template(os.environ['GALAXY_URL']).safe_substitute({'DOCKER_HOST': galaxy_ip})
    gi = _test_url(url, key, history_id)
    if gi is not None:
        return gi

    ### Failover, fully auto-detected URL ###
    # Remove trailing slashes
    app_path = os.environ['GALAXY_URL'].rstrip('/')
    # Remove protocol+host:port if included
    app_path = ''.join(app_path.split('/')[3:])

    if 'GALAXY_WEB_PORT' not in os.environ:
        # We've failed to detect a port in the config we were given by
        # galaxy, so we won't be able to construct a valid URL
        raise Exception("No port")
    else:
        # We should be able to find a port to connect to galaxy on via this
        # conf var: galaxy_paster_port
        galaxy_port = os.environ['GALAXY_WEB_PORT']

    built_galaxy_url = 'http://%s:%s/%s' %  (galaxy_ip.strip(), galaxy_port, app_path.strip())
    url = built_galaxy_url.rstrip('/')

    gi = _test_url(url, key, history_id)
    if gi is not None:
        return gi

    ### Fail ###
    msg = "Could not connect to a galaxy instance. Please contact your SysAdmin for help with this error"
    if '127.0.0.1' in os.environ['GALAXY_URL']:
        msg += (
            "\nYou seem to be running galaxy on localhost. "
            "By binding to 127.0.0.1, you prevent the docker "
            "based interactive environment from contacting the host, "
            "as the host galaxy refuses to answer requests that "
            "don't come from 127.0.0.1, like this docker container."
        )
    raise Exception(msg)

# number of seconds to cache history/dataset lookups
CACHE_TIME = 3

# Split a path into hash of components
def path_type(path):
    parts = filter(lambda x: len(x)>0, path.split('/'))
    if path=='/':
        return ('root',dict())
    elif path=='/histories':
        return ('histories',dict())
    elif len(parts)==2 and parts[0]=='histories':
        return ('datasets',dict(h_name=unesc_filename(parts[1])))
    elif len(parts)==3 and parts[0]=='histories':
        return ('data',dict(h_name=unesc_filename(parts[1]), ds_name=unesc_filename(parts[2])))
    print "Unknown : %s"%path
    return ('',0)

# Escape/unescape slashes in filenames
def esc_filename(fname):
    def esc(m):
        c=m.group(0)
        if c=='%':
            return '%%'
        elif c=='/':
            return '%-'
    return re.sub(r'%|/', esc, fname)

# Escape/unescape slashes in filenames
def unesc_filename(fname):
    def unesc(m):
        str=m.group(0)
        if str=='%%':
            return '%'
        elif str=='%-':
            return '/'

    return re.sub(r'%(.)', unesc, fname)

def parse_name_with_id(fname):
    #1cd8e2f6b131e891
    m = re.match(r"^(?P<name>.*)-(?P<id>[0-9a-f]{16})", fname)
    if m is not None:
        return (m.group('name'), m.group('id'))
    else:
        return (fname,'')


class Context(LoggingMixIn, Operations):
    'Prototype FUSE to galaxy histories'

    def __init__(self, gx_url, api_key):
        gx = get_galaxy_connection()
        self.gi = galaxy.GalaxyInstance(url=gx.gi.url.replace('/api', ''), key=api_key)
        self.datasets_cache = {}
        self.histories_cache = {'time':None, 'contents':None}

    def getattr(self, path, fh=None):
        #uid, gid, pid = fuse_get_context()
        (typ,kw) = path_type(path)
        now = time.time()
        if typ=='root' or typ=='histories':
            # Simple directory
            st = dict(st_mode=(S_IFDIR | 0555), st_nlink=2)
            st['st_ctime'] = st['st_mtime'] = st['st_atime'] = now
        elif typ=='datasets':
            # Simple directory
            st = dict(st_mode=(S_IFDIR | 0555), st_nlink=2)
            st['st_ctime'] = st['st_mtime'] = st['st_atime'] = now
        elif typ=='data':
            # A file, will be a symlink to a galaxy dataset
            d = self._dataset(kw)
            t = time.mktime(time.strptime(d['update_time'],'%Y-%m-%dT%H:%M:%S.%f'))
            fname = esc_filename(d['file_name'])
            st = dict(st_mode=(S_IFLNK | 0444), st_nlink=1,
                              st_size=len(fname), st_ctime=t, st_mtime=t,
                              st_atime=t)
            #st = dict(st_mode=(S_IFREG | 0444), st_nlink=1,
            #                  st_size=fname, st_ctime=t, st_mtime=t,
            #                  st_atime=t)
        else:
            raise FuseOSError(ENOENT)
        return st

    # Return a symlink for the given dataset
    def readlink(self, path):
        (typ,kw) = path_type(path)
        if typ=='data':
            d = self._dataset(kw)
            return d['file_name']
        raise FuseOSError(ENOENT)

    def read(self, path, size, offset, fh):
        raise RuntimeError('unexpected path: %r' % path)

    # Lookup all histories in galaxy; cache
    def _histories(self):
        cache = self.histories_cache
        now = time.time()
        if cache['contents'] is None or now - cache['time'] > CACHE_TIME:
            cache['time'] = now
            cache['contents'] = self.gi.histories.get_histories()
        return cache['contents']

    # Find a specific history by name
    def _history(self,h_name):
        (fixed_name, hist_id) = parse_name_with_id(h_name)
        h = filter(lambda x: x['name']==fixed_name, self._histories())
        if len(h)==0:
            raise FuseOSError(ENOENT)
        if len(h)>1:
            h = filter(lambda x: x['id']==hist_id, self._histories())
            if len(h)==0:
                raise FuseOSError(ENOENT)
            if len(h)>1:
                print "Too many histories with identical names and IDs"
            return h[0]
        return h[0]

    # Lookup all datasets in the specified history; cache
    def _datasets(self, h):
        id = h['id']
        cache = self.datasets_cache
        now = time.time()
        if id not in cache or now - cache[id]['time'] > CACHE_TIME:
            cache[id] = {'time':now,
                         'contents':self.gi.histories.show_history(id,contents=True,details='all')}
        return cache[id]['contents']

    # Find a specific dataset - the 'kw' parameter is from path_type() above
    def _dataset(self, kw):
        h = self._history(kw['h_name'])
        ds = self._datasets(h)
        (d_name, d_id) = parse_name_with_id(kw['ds_name'])
        d = filter(lambda x: x['name']==d_name, ds)

        if len(d)==0:
            raise FuseOSError(ENOENT)
        if len(d)>1:
            d = filter(lambda x: x['name']==d_name and x['id'] == d_id, ds)
            if len(d)==0:
                raise FuseOSError(ENOENT)
            if len(d)>1:
                print "Too many datasets with that name and ID"
            return d[0]
        if 'file_name' not in d[0]:
            print "Unable to find file of dataset.  Have you set : expose_dataset_path = True"
            raise FuseOSError(ENOENT)
        return d[0]

    # read directory contents
    def readdir(self, path, fh):
        (typ,kw) = path_type(path)
        if typ=='root':
            return ['.', '..', 'histories']
        elif typ=='histories':
            hl = self._histories()
            # Count duplicates
            hist_count = {}
            for h in hl:
                try:
                    hist_count[h['name']] += 1
                except:
                    hist_count[h['name']] = 1
            # Build up results manually
            results = ['.', '..']
            for h in hl:
                if h['name'] in hist_count and hist_count[h['name']] > 1:
                    results.append(esc_filename(h['name'] + '-' + h['id']))
                else:
                    results.append(esc_filename(h['name']))
            return results
        elif typ=='datasets':
            h = self._history(kw['h_name'])
            ds = self._datasets(h)
            #print ds
            # Count duplicates
            d_count = {}
            for d in ds:
                try:
                    d_count[d['name']] += 1
                except:
                    d_count[d['name']] = 1
            results = ['.', '..']
            for d in ds:
                if d['name'] in d_count and d_count[d['name']] > 1:
                    results.append(esc_filename(d['name'] + '-' + d['id']))
                else:
                    results.append(esc_filename(d['name']))
            return results

    # Disable unused operations:
    access = None
    flush = None
    getxattr = None
    listxattr = None
    open = None
    opendir = None
    release = None
    releasedir = None
    statfs = None


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Mount Galaxy Datasets for direct read access using FUSE.")
    parser.add_argument("apikey",
                        help="Galaxy API key for the account to read")
    parser.add_argument("-m", "--mountpoint", default="galaxy_files",
                        help="Directory under which to mount the Galaxy Datasets.")
    args = parser.parse_args()

    # Create the directory if it does not exist
    if not os.path.exists(args.mountpoint):
        os.makedirs(args.mountpoint)

    gx_url = get_galaxy_connection()
    print gx_url

    fuse = FUSE(Context(gx_url, args.apikey),
                args.mountpoint,
                foreground=True,
                ro=True)
