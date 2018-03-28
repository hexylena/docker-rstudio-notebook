# Docker RStudio Container

RStudio running in a docker container. This image can be used to integrate RStudio into Galaxy.
A variety of different packages are pre-installed and can be used right away.

This docker container is used by the [Galaxy-RStudio project](https://github.com/erasche/docker-rstudio-notebook).

## Usage

* Build your own image and run it

 [Docker](https://www.docker.com) is a pre-requirement for this project. You can build the container with:
 ```bash
 $ docker build -t rstudio-notebook .
 ```
 The build process can take some time, but if finished you can run your container with:
 ```bash
 $ docker run -p 8787:8787 -v /home/user/foo/:/import/ -t rstudio-notebook
 ```
 and you will have a running [RStudio](http://rstudio.com) instance on ``http://localhost:8787/``.

* Run a pre-built image from the docker registry

 ```bash
 $ docker run -p 8787:8787 -v `pwd`/foo:/import erasche/docker-rstudio-notebook
 ```

### Environment Variables

Several environment variables are available by default, per IE rough standards

#### Build-Time Variables

Variable       | Use
-------------- | ----
`RSTUDIO_FULL` | Build RStudio with the full complement of Bio packages (warning, slow)

#### Run-Time Variables

Variable            | Use
------------------- | ---
`GALAXY_WEB_PORT`   | Port on which Galaxy is running, if applicable
`CORS_ORIGIN`       | If the notebook is proxied, this is the URL the end-user will see when trying to access a notebook
`DOCKER_PORT`       | Used in Galaxy Interactive Environments to ensure that proxy routes are unique and accessible
`API_KEY`           | Galaxy API Key with which to interface with Galaxy
`HISTORY_ID`        | ID of current Galaxy History, used in easing the dataset upload/download process
`REMOTE_HOST`       | Unused
`GALAXY_URL`        | URL at which Galaxy is accessible
`DEBUG`             | Enable debugging mode, mostly for developers


## Licence (MIT)

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
