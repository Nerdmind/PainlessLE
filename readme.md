# PainlessLE – A wrapper script for Certbot
With *PainlessLE* you can easily obtain an [X.509 certificate](https://www.rfc-editor.org/info/rfc5280) for your hostnames from the *Let's Encrypt Certification Authority (CA)*, without the need to have a dedicated web server running.

In addition, with *PainlessLE* you'll manage your certificates and RSA/ECDSA private key files by yourself, so *Certbot* will never rotate your private key files automatically (which was useful in the days before [HPKP](https://www.rfc-editor.org/info/rfc7469) was considered deprecated). You also can choose a custom install directory and customize the filenames of the certificate files.

However, this means that you also have to take care of the periodic renewal of the certificates by yourself. If you are just looking for a tool which automatically *copies* the new certificate files after issuance (or renewal) from *Certbot's* default location to a custom directory structure with custom UNIX permissions (while you let *Certbot* manage the certificates and periodic renewal by itself), then take a look at [*CertDeploy*](https://github.com/Nerdmind/CertDeploy), a deploy-hook script for *Certbot*.

## Requirements
The [*Certbot* client](https://certbot.eff.org/) must be installed on your machine because *PainlessLE* will use this piece of software to communicate over the [ACME protocol](https://www.rfc-editor.org/info/rfc8555) with the ACME endpoint of *Let's Encrypt* to run the ACME challenge.

*There are currently no known further requirements for *PainlessLE* on a recent *Debian GNU/Linux* system.*

## Installation
Beside the possibility to manually place the script in some directory and just run it, you can use the more elegant way with [*GNU Stow*](https://www.gnu.org/software/stow/) to map the content of the `package` directory via symbolic links properly to `/usr/local`:

~~~bash
cd /usr/local/src
git clone $REPO && cd $REPO
stow -t /usr/local package
~~~

Make sure that no unprivileged user has write permissions on `/usr/local/sbin`, the symlink targets (in case you've choosen `stow`) and/or the `painless-le` script, because PainlessLE is usually executed with `root` privileges.

## Configuration
You can change the `ACME_ENDPOINT` variable to the URL of the ACME staging API for testing purposes.

## Usage
~~~
painless-le [OPTIONS] TARGET_DIR DNS_DOMAIN [DNS_DOMAIN ...]
painless-le /etc/painless-le/example.org/ example.org www.example.org
~~~

### Required positional arguments:
* `TARGET_DIR`: The path to the target directory where the certificate files shall be installed. The target directory must contain an existing RSA/ECDSA private key file (in PEM format).

* `DNS_DOMAIN`: A list of one or more DNS hostnames to include within the certificate.

### Additional command-line options:
* `[-K]`: Filename of the existing private key in target directory. (default: `confidential.pem`)
* `[-I]`: Filename for the intermediate certificate in target directory. (default: `intermediate.pem`)
* `[-C]`: Filename for the standalone certificate in target directory. (default: `certificate_only.pem`)
* `[-F]`: Filename for the certificate+intermediate in target directory. (default: `certificate_full.pem`)

## Example
PainlessLE assumes that there already is an RSA/ECDSA private key file (in PEM format) in the target directory. The private key file should already have the desired UNIX permissions that the new certificate files will inherit.

Let's assume you want to get an X.509 certificate from the *Let's Encrypt* CA for three hostnames of your domain `example.org` (main domain, blog subdomain and shop subdomain). You already have the private key with the desired UNIX permissions stored within the following example directory:

	/etc/painless-le/example.org/
	└── [-rw-r----- user     group    ]  confidential.pem

The next step is to call `painless-le` while providing at least the two required positional arguments (`TARGET_DIR` and `DNS_DOMAIN`) which are described above.

In this example, the complete command-line string with the desired target directory `/etc/painless-le/example.org` and the desired hostnames `example.org`, `blog.example.org` and `shop.example.org` looks as follows:

	painless-le /etc/painless-le/example.org/ example.org blog.example.org shop.example.org

The Certbot client will now contact the ACME server of *Let's Encrypt* and spawns a temporary standalone web server on your machine to accomplish the ACME challenge. If all works fine, you have nothing to intervene.

After the command was successfully executed, you will see your certificate files within your desired target directory (the certificate files will inherit the UNIX permissions of the `confidential.pem` file) and you're done:

	/etc/painless-le/example.org/
	├── [-rw-r----- user     group    ]  certificate_full.pem
	├── [-rw-r----- user     group    ]  certificate_only.pem
	├── [-rw-r----- user     group    ]  confidential.pem
	└── [-rw-r----- user     group    ]  intermediate.pem
