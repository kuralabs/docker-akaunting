==========================
Akaunting Docker Container
==========================

About
=====

Akaunting is a free, open source and online accounting software designed for
small businesses and freelancers. It is built with modern technologies such as
Laravel, Bootstrap, jQuery, RESTful API etc. Thanks to its modular structure,
Akaunting provides an awesome App Store for users and developers.

    https://akaunting.com/

This repository holds the source of the all-in-one Akaunting Docker image
available at:

    https://hub.docker.com/r/kuralabs/akaunting/

Usage
=====

Build me with::

    docker build --tag kuralabs/akaunting:latest .

In development, run me with::

    $ MYSQL_ROOT_PASSWORD=[MYSQL SECURE ROOT PASSWORD] ./run/akaunting-dev.sh

In production, run me with::

    $ MYSQL_ROOT_PASSWORD=[MYSQL SECURE ROOT PASSWORD] ./run/akaunting.sh


License
=======

.. code-block:: txt

   Copyright (C) 2017-2018 KuraLabs S.R.L

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing,
   software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
   KIND, either express or implied.  See the License for the
   specific language governing permissions and limitations
   under the License.
