#!/bin/bash
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Painless Let's Encrypt Certificate Issuing [Thomas Lange <code@nerdmind.de>] #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
#                                                                              #
# Easily get an X.509 certificate from the Let's Encrypt Certificate Authority #
# for a bunch of hostnames without having an HTTP server installed. The script #
# assumes that you have an existing RSA private key stored within your desired #
# install directory (with the filename which is defined in "${CONFIDENTIAL}"). #
#                                                                              #
# ARGUMENT_DIRECTORY: Full path to the install directory for the certificates. #
# ARGUMENT_HOSTNAMES: List of hostnames for the certificate: example.org[:...] #
#                                                                              #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

[ -z "$1" ] && echo 'Missing argument $1' && exit 1 || ARGUMENT_DIRECTORY="$1"
[ -z "$2" ] && echo 'Missing argument $2' && exit 1 || ARGUMENT_HOSTNAMES="$2"

#===============================================================================
# Define the ACME endpoint address
#===============================================================================
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
openssl req -config <(cat "${OPENSSLCONF}" <(printf "[SAN]\nsubjectAltName=DNS:`echo ${ARGUMENT_HOSTNAMES} | sed "s/:/,DNS:/g"`")) \
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
certbot certonly --authenticator standalone --text --server "${LETSENCRYPT_ENDPOINT}" --csr "${REQUESTFILE}" \
--cert-path "${CERTIFICATE_ONLY}" --fullchain-path "${CERTIFICATE_FULL}" --chain-path "${INTERMEDIATE}"

#===============================================================================
# Adjust the UNIX permissions with owner and group for the new created files
#===============================================================================
chmod --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"
chown --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"

#===============================================================================
# Execute defined command AFTER the ACME challenge is completed
#===============================================================================
[ ! -z "${LETSENCRYPT_COMMAND_AFTER}" ] && $($LETSENCRYPT_COMMAND_AFTER)