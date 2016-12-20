# PainlessLE: Let's Encrypt Certificate Issuing
Painless issuing a single [X.509 certificate](https://tools.ietf.org/html/rfc5280) for a bunch of hostnames from the **Let's Encrypt** Certification Authority (CA) without having a HTTP server installed (or for those people who do not want to touch their HTTP web directories and place a specific file to accomplish the ACME challenge). PainlessLE assumes that there is already a manually created RSA private key which is used for the Certificate-Signing-Request (CSR) by OpenSSL. The location for the RSA private key is defined within the `"CONFIDENTIAL"` variable and the path should exist with the correct UNIX file permissions.

## Configuration
Change the `LETSENCRYPT_ENDPOINT` to the address of the ACME staging API for testing purposes. You also can define a command within `LETSENCRYPT_COMMAND_BEFORE` to shutting down a running webserver to release the HTTP(S) port for the standalone webserver before certbot runs the ACME challenge. You can restart your webserver after the ACME challenge is completed within `LETSENCRYPT_COMMAND_AFTER`.

## Arguments
1. `ARGUMENT_DIRECTORY` contains a string with the directory path where the certificates should be installed. This directory should already contain a manually created RSA private key for the Certificate-Signing-Request (CSR). It's always a good idea to handle the RSA private keys manually because you may use [HTTP Public-Key-Pinning (HPKP)](https://tools.ietf.org/html/rfc7469) so that you must ensure, that the RSA private key does not change.

2. `ARGUMENT_HOSTNAMES` contains a string with the hostnames to include within the certificate. The string must be formatted as follows because he get injected directly into to OpenSSL command to generate the Certificate-Signing-Request: `DNS:example.org,DNS:blog.example.org,DNS:shop.example.org`

## Example
Lets assume that you want to get a single X.509 certificate from the Let's Encrypt CA which includes three hostnames of your domain `example.org` (main domain, blog subdomain and shop subdomain). You already have a RSA private key with the correct UNIX file permissions stored within the following example directory with the name `confidential.pem`:

	/etc/painless-le/example.org/
	└── [-rw-r----- user     group    ]  confidential.pem

The next step is to execute `painless-le.sh` and providing the only two command-line arguments which are described above. In this example, the complete command-line string with the desired install directory `/etc/painless-le/example.org` and the desired hostnames `example.org`, `blog.example.org` and `shop.example.org` looks as follows:

	painless-le.sh /etc/painless-le/example.org/ "DNS:example.org,DNS:blog.example.org,DNS:shop.example.org"

The certbot client will now contacting the ACME challenge servers and runs a temporary standalone webserver on your machine to accomplish the ACME challenge. If all works fine, you have nothing to intervene. After the command was successfully executed, you will see your certificates within your desired install directory (the certificates inherit the permissions of the `confidential.pem` file) and you're done:

	/etc/painless-le/example.org/
	├── [-rw-r----- user     group    ]  certificate_full.pem
	├── [-rw-r----- user     group    ]  certificate_only.pem
	├── [-rw-r----- user     group    ]  confidential.pem
	└── [-rw-r----- user     group    ]  intermediate.pem

**Note:** The new certificates inherit the UNIX file permissions (**chmod** and **chown**) of the RSA private key `confidential.pem`!