#!/usr/bin/env python

"""Usage:
    get_sequences [--log-level=<log-level>] <regions-file>

-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
<regions-file>
    File containing locations of regions to get sequences for.
"""

import docopt
import ordutils.log as log
import ordutils.options as opt
import requests
import schema
import sys
import time

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())
REGIONS_FILE = "<regions-file>"

# TODO: Allow species to be specified
# TODO: Allow strand to be specified
URL = "http://rest.ensembl.org/sequence/region/mouse/{c}:{s}..{e}:1"

# Allow request rate to be specified
REQUESTS_PER_SEC = 10


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level.")
        opt.validate_file_option(
            options[REGIONS_FILE],
            "Could not open region locations file.")
    except schema.SchemaError as exc:
        exit("Exiting. " + exc.code)


def get_sequence(logger, chromosome, start, end):
    logger.debug("Getting sequence for {c}:{s}-{e}".format(
        c=chromosome, s=start, e=end))

    url = URL.format(c=chromosome, s=start, e=end)

    r = requests.get(url, headers={"Content-Type": "text/x-fasta"})

    if not r.ok:
        r.raise_for_status()
        sys.exit()

    return r.text


def get_sequences(logger, regions_file):
    logger.info("Reading region locations from '" + regions_file + "'")
    with open(regions_file, 'r') as f:
        for line in f:
            chromosome, start, end = line.strip().split(",")
            print(get_sequence(logger, chromosome, start, end).strip())
            time.sleep(1.0 / REQUESTS_PER_SEC)


def main(docstring):
    # Read in and validate command line options
    options = docopt.docopt(docstring, version="get_sequences v0.1")
    validate_command_line_options(options)

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    get_sequences(logger, options[REGIONS_FILE])

if __name__ == "__main__":
    main(__doc__)

