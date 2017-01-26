# PainlessLE: Let's Encrypt Certificate Issuing
Painless issuing a single [X.509 certificate](https://tools.ietf.org/html/rfc5280) for a bunch of hostnames from the **Let's Encrypt** Certification Authority (CA) without having an HTTP server installed (or for those people who do not want to touch their HTTP web directories and place a specific file to accomplish the ACME challenge). PainlessLE assumes that there is already a manually created RSA private key which is used for the Certificate-Signing-Request (CSR) by OpenSSL. The location for the RSA private key is defined within the `"CONFIDENTIAL"` variable and the path should exist with the correct UNIX file permissions.

## Requirements
The [Certbot client](https://certbot.eff.org/) must be installed on your machine because PainlessLE uses this piece of software to communicate over the [ACME protocol](https://tools.ietf.org/html/draft-ietf-acme-acme-01) with the ACME endpoint of Let's Encrypt and runs the ACME challenge. There are no known further requirements for using PainlessLE on Debian GNU/Linux at this time.

## Configuration
Change the `LETSENCRYPT_ENDPOINT` to the address of the ACME staging API for testing purposes. You also can define a command within `LETSENCRYPT_COMMAND_BEFORE` to shutting down a running webserver to release the HTTP(S) port for the standalone webserver before certbot runs the ACME challenge. You can restart your webserver after the ACME challenge is completed within `LETSENCRYPT_COMMAND_AFTER`.

## Arguments

### Required command-line options:
* `[-i]`: Contains a string with the directory path where the certificates should be installed. This directory should already contain a manually created RSA private key (filename can be overwritten by providing the `[-K]` option) for the Certificate-Signing-Request (CSR). It's always a good idea to handle the RSA private keys manually because you may use [HTTP Public-Key-Pinning (HPKP)](https://tools.ietf.org/html/rfc7469) so that you must ensure, that the RSA private key does not change.

* `[-h]`: Contains a colon (`:`) separated string with the DNS hostnames to include within the certificate. The string must be formatted as follows, without containing colons anywhere except **between** the hostnames: `example.org:blog.example.org:shop.example.org`

### Additional command-line options:
* `[-K]`: Filename for the existing RSA private key relative to `[-i]`
* `[-I]`: Target filename for the intermediate certificate relative to `[-i]`
* `[-C]`: Target filename for the certificate only file relative to `[-i]`
* `[-F]`: Target filename for the certificate full fiĺe relative to `[-i]`

## Example
Lets assume that you want to get a single X.509 certificate from the Let's Encrypt CA which includes three hostnames of your domain `example.org` (main domain, blog subdomain and shop subdomain). You already have an RSA private key with the correct UNIX file permissions stored within the following example directory with the name `confidential.pem`:

	/etc/painless-le/example.org/
	└── [-rw-r----- user     group    ]  confidential.pem

The next step is to execute `painless-le.sh` and providing the `-i` and `-h` options which are described above. In this example, the complete command-line string with the desired install directory `/etc/painless-le/example.org` and the desired hostnames `example.org`, `blog.example.org` and `shop.example.org` looks as follows:

	painless-le.sh -i /etc/painless-le/example.org/ -h example.org:blog.example.org:shop.example.org

The certbot client will now contact the ACME challenge servers and runs a temporary standalone webserver on your machine to accomplish the ACME challenge. If all works fine, you have nothing to intervene. After the command was successfully executed, you will see your certificates within your desired install directory (the certificates inherit the permissions of the `confidential.pem` file) and you're done:

	/etc/painless-le/example.org/
	├── [-rw-r----- user     group    ]  certificate_full.pem
	├── [-rw-r----- user     group    ]  certificate_only.pem
	├── [-rw-r----- user     group    ]  confidential.pem
	└── [-rw-r----- user     group    ]  intermediate.pem

**Note:** The new certificates inherit the UNIX file permissions (**chmod** and **chown**) of the RSA private key `confidential.pem`!