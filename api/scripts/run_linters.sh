#!/bin/sh

set -e;

PATHS_TO_LINT="$*"

FLAKE8_VERSION=`flake8 --version`
MYPY_VERSION=`mypy --version`
PYLINT_VERSION=`pylint --version`
BLACK_VERSION=`black --version`
ISORT_VERSION=`isort --version-number`

echo 'Running linters on path(s): ' $PATHS_TO_LINT
echo '----------------------------------------------------------------------'

echo 'Running' $MYPY_VERSION;
mypy --show-error-codes $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Running flake8' $FLAKE8_VERSION;
pflake8 -j6 $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Running' $BLACK_VERSION;
black --config pyproject.toml --check --diff $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Running isort' $ISORT_VERSION;
isort --settings-path pyproject.toml --check-only --diff $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Running' $PYLINT_VERSION;
pylint --jobs 8 authentication barber core customer tasks websockets;
echo '----------------------------------------------------------------------'

echo 'All linters ok!';
