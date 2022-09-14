#!/usr/bin/python
"""
Copyright 2021 ARC Centre of Excellence for Climate Extremes 

author: Paola Petrelli <paola.petrelli@utas.edu.au>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This script is used to support download codes by providing utility functions:
to write logs, check if existing files need updates etc.

Created:
 2022-06-22
Last change:
 2022-06-22
"""

import os
import hashlib
import logging
import calendar
from datetime import datetime
from time import gmtime, strptime
import requests
import dateutil.parser
import pytz

def set_log(name, fname, level):
    """Set up logging with a file handler

    Parameters
    ----------
    name: str
        Name of logger object
    fname: str
         Log output filename
    level: str
        Base logging level
    """

    # First disable default root logger
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)
    # start a logger
    logger = logging.getLogger(name)
    # set a formatter to manage the output format of our handler
    formatter = logging.Formatter(
        "%(asctime)s | %(message)s", "%H:%M:%S")
    minimal = logging.Formatter("%(message)s")
    if level == "debug": 
        minimal = logging.Formatter("%(levelname)s: %(message)s")
    # set the level passed as input, has to be logging.LEVEL not a string
    log_level = logging.getLevelName(level.upper())
    logger.setLevel(log_level)
    # add a handler for console this will have the chosen level
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    console_handler.setFormatter(minimal)
    logger.addHandler(console_handler)
    # add a handler for the log file, this is set to INFO level
    file_handler = logging.FileHandler(fname)
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(minimal)
    logger.addHandler(file_handler)
    # return the logger object
    logger.propagate = False
    return logger
 

def check_md5sum(filename, logger):
    """Check local and remote md5 checksum and return comparison
    This is much slower then checking modified date
    """

    m = hashlib.md5()
    self.ftp.retrbinary('RETR %s' % filename, m.update)
    ftp_md5 =  m.hexdigest()
    local_md5 = hashlib.md5(open(filename,'rb').read()).hexdigest()
    logger.debug(f"File: {filename}")
    logger.debug(f"Local md5: {local_md5}")
    logger.debug(f"ftp md5: {ftp_md5}")
    different = local_md5 != ftp_md5
    return different


def check_mdt(req, fpath, logger, remoteModDate=None, furl=None,
              head_key='Last-modified'):
    """Check local and remote modified time and return comparison
       You have to pass either the remote last modified date or 
       the file url to try to retrieve it 
    """
    if not remoteModDate:
        response = req.head(furl)
        remoteModDate = response.headers[head_key]
    remoteModDate = dateutil.parser.parse(remoteModDate)
    localModDate = datetime.fromtimestamp(
                   os.path.getmtime(fpath))
    localModDate = localModDate.replace(tzinfo=pytz.UTC)
    to_update = localModDate < remoteModDate
    logger.debug(f"File: {fpath}")
    logger.debug(f"Local mod_date: {localModDate}")
    logger.debug(f"ftp mod_date: {remoteModDate}")
    logger.debug(f"to update: {to_update}")
    return to_update


def print_summary(updated, new, error, logger):
    """Print a summary of new, updated and error files to log file"""

    logger.info("==========================================")
    logger.info("Summary")
    logger.info("==========================================")
    logger.info("These files were updated: ")
    for f in updated:
        logger.info(f"{f}")
    logger.info("==========================================")
    logger.info("These are new files: ")
    for f in new:
        logger.info(f"{f}")
    logger.info("==========================================")
    logger.info("These files and problems: ") 
    for f in error:
        logger.info(f"{f}")
    logger.info("\n\n") 


def get_credentials(fname, token=False):
    """Open file and read username/passowrd or token

    Requires information to be formatted as
    1st line: username
    2nd line: password
    or if token True
    1st line: token
    """

    f = open(fname, "r")
    lines = f.readlines()
    if token:
        utoken = lines[0].replace("\n","")
        credentials = (token,)
    else:
        uname = lines[0].replace("\n","")
        passw = lines[1].replace("\n","")
        credentials = (uname,passw)
    return credentials
