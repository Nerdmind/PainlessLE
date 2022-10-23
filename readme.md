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
First, change the `LETSENCRYPT_ENDPOINT` to the address of the ACME staging API for testing purposes.

You also can define a command within `LETSENCRYPT_COMMAND_BEFORE` to shut down a running web server to release the HTTP port for the standalone web server before Certbot runs the ACME challenge. You can restart your web server after the ACME challenge is completed within `LETSENCRYPT_COMMAND_AFTER`.

## Usage

### Required command-line options:
* `[-i]`: Contains a string with the directory path where the certificates should be installed. This directory should already contain a manually created private key (filename can be overridden by providing the `[-K]` option) for the Certificate-Signing-Request (CSR).

* `[-h]`: Contains a colon (`:`) separated string with the DNS hostnames to include within the certificate. The string must be formatted as follows, without containing colons anywhere except **between** the hostnames: `example.org:blog.example.org:shop.example.org`

### Additional command-line options:
* `[-K]`: Filename for the existing private key relative to `[-i]`
* `[-I]`: Target filename for the intermediate certificate relative to `[-i]`
* `[-C]`: Target filename for the certificate only file relative to `[-i]`
* `[-F]`: Target filename for the certificate full file relative to `[-i]`

## Example
PainlessLE assumes that there is already a manually created private key which is used for the Certificate-Signing-Request (CSR) by OpenSSL. The location of the private key is defined within the `"CONFIDENTIAL"` variable and the file should exist with the desired UNIX permissions that the certificate files shall inherit.

Lets assume you want to get an X.509 certificate from the Let's Encrypt CA which includes three hostnames of your domain `example.org` (main domain, blog subdomain and shop subdomain). You already have a private key with the desired UNIX file permissions stored within the following example directory with the name `confidential.pem`:

	/etc/painless-le/example.org/
	└── [-rw-r----- user     group    ]  confidential.pem

The next step is to execute `painless-le` while providing the `-i` and `-h` options which are described above. In this example, the complete command-line string with the desired target directory `/etc/painless-le/example.org` and the desired hostnames `example.org`, `blog.example.org` and `shop.example.org` looks as follows:

	painless-le -i /etc/painless-le/example.org/ -h example.org:blog.example.org:shop.example.org

The Certbot client will now contact the ACME challenge server and spawns a temporary standalone web server on your machine to accomplish the ACME challenge. If all works fine, you have nothing to intervene.

After the command was successfully executed, you will see your certificates within your desired target directory (the certificate files will inherit the UNIX permissions of the `confidential.pem` file) and you're done:

	/etc/painless-le/example.org/
	├── [-rw-r----- user     group    ]  certificate_full.pem
	├── [-rw-r----- user     group    ]  certificate_only.pem
	├── [-rw-r----- user     group    ]  confidential.pem
	└── [-rw-r----- user     group    ]  intermediate.pem

**Note:** The new certificate files inherit the UNIX file permissions (**chmod** and **chown**) of the private key `confidential.pem`!
