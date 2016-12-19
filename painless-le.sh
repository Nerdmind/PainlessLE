#!/bin/bash
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Painless Let's Encrypt Certificate Issuing [Thomas Lange <code@nerdmind.de>] #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#                                                                              #
# PainlessLE makes it easy to issue a X.509 certificate from the Let's Encrypt #
# Certification Authority (CA) for a bunch of hostnames without already having #
# a HTTP server installed. PainlessLE assumes that there is already a manually #
# created RSA private which is used for the Certificate-Signing-Request (CSR). #
# The location for the RSA private key is defined within "${CONFIDENTIAL}".    #
#                                                                              #
# ARGUMENT_DIRECTORY: Full path to the install directory for the certificates  #
# ARGUMENT_HOSTNAMES: Hostnames for CSR: DNS:example.org,DNS:blog.example.org  #
#                                                                              #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

[ -z "$1" ] && echo 'Missing argument $1' && exit 1 || ARGUMENT_DIRECTORY="$1"
[ -z "$2" ] && echo 'Missing argument $2' && exit 1 || ARGUMENT_HOSTNAMES="$2"

#===============================================================================
# Information about the Let's encrypt account
#===============================================================================
LETSENCRYPT_MAILADDR="john.doe@example.org"
LETSENCRYPT_ENDPOINT="https://acme-v01.api.letsencrypt.org/directory"
#LETSENCRYPT_ENDPOINT="https://acme-staging.api.letsencrypt.org/directory"

#===============================================================================
# Define commands who are executed BEFORE and AFTER the ACME challenge
#===============================================================================
#LETSENCRYPT_COMMAND_BEFORE="systemctl stop apache2"
#LETSENCRYPT_COMMAND_AFTER="systemctl start apache2"

#===============================================================================
# Define required paths
#===============================================================================
     OPENSSLCONF="/etc/ssl/openssl.cnf"
     REQUESTFILE=`mktemp -u /tmp/letsencrypt.XXXX.csr`
    CONFIDENTIAL="${ARGUMENT_DIRECTORY%/}/confidential.pem"
    INTERMEDIATE="${ARGUMENT_DIRECTORY%/}/intermediate.pem"
CERTIFICATE_ONLY="${ARGUMENT_DIRECTORY%/}/certificate_only.pem"
CERTIFICATE_FULL="${ARGUMENT_DIRECTORY%/}/certificate_full.pem"

#===============================================================================
# Generate Certificate-Signing-Request (CSR)
#===============================================================================
openssl req -config <(cat "${OPENSSLCONF}" <(printf "[SAN]\nsubjectAltName=${ARGUMENT_HOSTNAMES}")) \
-new -sha256 -key "${CONFIDENTIAL}" -out "${REQUESTFILE}" -outform der -reqexts SAN -subj "/"

#===============================================================================
# Checking if Certificate-Signing-Request (CSR) was successfully created
#===============================================================================
if [ $? != 0 ]; then
	echo "[ABORTING]: Certificate-Signing-Request (CSR) could not be created!"
	exit 1
fi

#===============================================================================
# Delete previous certificates from the install directory
#===============================================================================
[ -f "${INTERMEDIATE}" ]     && rm "${INTERMEDIATE}"
[ -f "${CERTIFICATE_ONLY}" ] && rm "${CERTIFICATE_ONLY}"
[ -f "${CERTIFICATE_FULL}" ] && rm "${CERTIFICATE_FULL}"

#===============================================================================
# Execute defined command BEFORE the ACME challenge is started
#===============================================================================
[ ! -z "${LETSENCRYPT_COMMAND_BEFORE}" ] && $($LETSENCRYPT_COMMAND_BEFORE)

#===============================================================================
# Execute Let's Encrypt and accomplish the ACME challenge to get the certificate
#===============================================================================
certbot certonly --authenticator standalone --text --server "${LETSENCRYPT_ENDPOINT}" --email "${LETSENCRYPT_MAILADDR}" \
--csr "${REQUESTFILE}" --cert-path "${CERTIFICATE_ONLY}" --fullchain-path "${CERTIFICATE_FULL}" --chain-path "${INTERMEDIATE}"

#===============================================================================
# Adjust the UNIX permissions with owner and group for the new created files
#===============================================================================
chmod --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"
chown --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"

#===============================================================================
# Execute defined command AFTER the ACME challenge is completed
#===============================================================================
[ ! -z "${LETSENCRYPT_COMMAND_AFTER}" ] && $($LETSENCRYPT_COMMAND_AFTER)