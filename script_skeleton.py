#!/usr/bin/python

"""Usage:
    <SCRIPT_NAME> [--log-level=<log-level>]

-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
"""

import docopt
import ordutils.log as log
import ordutils.options as opt
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())


def validate_command_line_options(options):
    # Validate command-line options
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
    except schema.SchemaError as exc:
        exit(exc.code)


def main(docstring):
    # Read in and validate command line options
    options = docopt.docopt(docstring, version="<SCRIPT_NAME> v0.1")
    validate_command_line_options(options)

    # Set up logger
    logger = log.getLogger(sys.stderr, options[LOG_LEVEL])

    # Rest of script...


if __name__ == "__main__":
    main(__doc__)
