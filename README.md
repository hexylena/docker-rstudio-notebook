Docker RStudio Container
========================

RStudio running in a docker container. This image can be used to integrate RStudio into Galaxy.
A variety of different packages are pre-installed and can be used right away.

This docker container is used by the [Galaxy-RStudio project](https://github.com/erasche/galaxy-rstudio).

Usage
=====

* Build your own image and run it

 [Docker](https://www.docker.com) is a pre-requirement for this project. You can build the container with:
 ```bash
  docker build -t rstudio-notebook . 
 ```
 The build process can take some time, but if finished you can run your container with:
 ```bash
  docker run -p 7777:8787 -v /home/user/foo/:/import/ -t rstudio-notebook
 ```
 and you will have a running [RStudio](http://rstudio.com) instance on ``http://localhost:8787/``.


Authors
=======

 * Bjoern Gruening
 * Eric Rasche

History
=======

- v0.1: Initial public release


Licence (MIT)
=============

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
