# pike-soap-helper

Here you'll find some helper stuff for using SOAP in [Pike](http://pike.lysator.liu.se/).
This module by no means utilise WSDL and fancy stuff, but are more for manually
building the envelope, body, parameters and such.

In the [test](test) directory you'll find some examples.

## Installation

You can put the `WS.pmod` directory anywhere you want and define the environment
variable `PIKE_MODULE_PATH` to point to the directory containing `WS.pmod`.

  export PIKE_MODULE_PATH=/path/to/dir/with/WS.pmod:$PIKE_MODULE_PATH

NOTE! You should not point to `WS.pmod` it self, but rather its parent directory.

Or put it in a directory already registered as a Pike module location if you
already have such a directory.
