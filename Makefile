PYTHON ?= python

.PHONY: install lint test all

install:
	$(PYTHON) -m pip install -r requirements-dev.txt

lint:
	$(PYTHON) -m pylint --disable=C0114,C0116 app.py package_app.py tests/test_app.py

test:
	$(PYTHON) -m pytest -vv

all:
	$(MAKE) install
	$(MAKE) lint
	$(MAKE) test
