docker-bioplatforms-composer
=================

Its the official docker compose container with some convenience Bioplatforms sh scripts.

Build using docker:

.. code:: bash

 > docker build -t bioplatformsaustralia/bioplatforms-composer:latest .

Then, it can build itself:

.. code:: bash

 > ./develop.sh build latest

Usage is shown to pad out this README.

.. code:: bash

 ## ./develop.sh build [service]                  (build a service from docker-compose-build.yml)
 ## ./develop.sh down [target|-]                  (down - optional target chooses compose file)
 ## ./develop.sh push [service]                   (push an image from docker-compose-build.yml)
 ## ./develop.sh run [target|-]                   (run - optional target chooses compose file)
 ## ./develop.sh run-builder                      (Run a build, typically produces a release tarball)
 ## ./develop.sh sanity                           (Print some info for sanity checking)
 ## ./develop.sh skeleton                         (Update/Create develop.sh/.env)
 ## ./develop.sh start [target|-]                 (start - optional target chooses compose file)
 ## ./develop.sh stop [target|-]                  (stop - optional target chooses compose file)
 ## ./develop.sh up [target|-]                    (up - optional target chooses compose file)
 ## ./develop.sh usage
 ##
 ## About:
 ##   Most calls are simple wrappers around docker-compose. In all cases the docker-compose command
 ## line is displayed, so it is trivial to copy/edit the compose command line if you wish to do so.
 ##
 ## Conventions:
 ##   o Env variables to set or pass through from current env are in .env
 ##   o Compose files are named docker-compose-<target>.yml
 ##   o Build services are in docker-compose-build.yml
 ##   o Build services in docker-compose-build.yml are suitable for push-ing
 ##   o Prod builds rely on ${GIT_TAG}, these scripts set that for you
 ##
 ## Example (Build and publish a Django project):
 ##   > ./develop.sh build base                             (build base image)
 ##   > ./develop.sh build builder                          (build builder image)
 ##   > ./develop.sh run-builder                            (run builder, typically produces a tarball)
 ##   > ./develop.sh build prod                             (build prod image using tarball from run-builder)
 ##   > ./develop.sh push prod                              (push prod image, assumes authenticated)
 ##
 ## Example (Build and start dev):
 ##   > ./develop.sh build base                             (build base image)
 ##   > ./develop.sh build dev                              (build dev image)
 ##   > ./develop.sh up                                     (up dev stack)
 ##
 ## Example (Run Aloe tests, assuming everything is built):
 ##   > ./develop.sh up selenium -d                         (background selenium)
 ##   > ./develop.sh up teststack -d                        (background teststack)
 ##   > ./develop.sh up aloe --force-recreate devaloe       (foreground aloe tests)
 ## ...and tear it down:
 ##   > ./develop.sh stop teststack                         (stop teststack)
 ##   > ./develop.sh rm teststack -v                        (rm teststack)
 ##   > ./develop.sh stop selenium                          (stop selenium)
