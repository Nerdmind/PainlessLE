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
# OPTION [-i]: Full path to the install directory for the certificates.        #
# OPTION [-h]: List of hostnames for the certificate: example.org[:...]        #
# OPTION [-K]: Filename for the existing RSA private key relative to [-i]      #
# OPTION [-I]: Target filename for the intermediate cert relative to [-i]      #
# OPTION [-C]: Target filename for the certificate only file relative to [-i]  #
# OPTION [-F]: Target filename for the certificate full file relative to [-i]  #
#                                                                              #
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

#===============================================================================
# Parsing command-line arguments with the getopts shell builtin
#===============================================================================
while getopts :i:h:K:I:C:F: option
do
	case $option in
		i) ARGUMENT_DIRECTORY="$OPTARG" ;;
		h) ARGUMENT_HOSTNAMES="$OPTARG" ;;
		K) ARGUMENT_CONFIDENTIAL="$OPTARG" ;;
		I) ARGUMENT_INTERMEDIATE="$OPTARG" ;;
		C) ARGUMENT_CERTIFICATE_ONLY="$OPTARG" ;;
		F) ARGUMENT_CERTIFICATE_FULL="$OPTARG" ;;
	esac
done

#===============================================================================
# Checking if all required command-line arguments are provided
#===============================================================================
[ -z "${ARGUMENT_DIRECTORY}" ] && echo "$0: Missing argument: [-i directory]" >&2
[ -z "${ARGUMENT_HOSTNAMES}" ] && echo "$0: Missing argument: [-h hostnames]" >&2

#===============================================================================
# Abort execution if required command-line argument is missing
#===============================================================================
[ -z "${ARGUMENT_DIRECTORY}" ] || [ -z "${ARGUMENT_HOSTNAMES}" ] && exit 1

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
     REQUESTFILE=`mktemp /tmp/painless-le.XXXXXXXXXX.csr`
    CONFIDENTIAL="${ARGUMENT_DIRECTORY%/}/${ARGUMENT_CONFIDENTIAL:-confidential.pem}"
    INTERMEDIATE="${ARGUMENT_DIRECTORY%/}/${ARGUMENT_INTERMEDIATE:-intermediate.pem}"
CERTIFICATE_ONLY="${ARGUMENT_DIRECTORY%/}/${ARGUMENT_CERTIFICATE_ONLY:-certificate_only.pem}"
CERTIFICATE_FULL="${ARGUMENT_DIRECTORY%/}/${ARGUMENT_CERTIFICATE_FULL:-certificate_full.pem}"

#===============================================================================
# Delete Certificate-Signing-Request (CSR) file on exit
#===============================================================================
trap 'rm ${REQUESTFILE}' EXIT

#===============================================================================
# Generate Certificate-Signing-Request (CSR)
#===============================================================================
openssl req -config <(cat "${OPENSSLCONF}" <(printf "[SAN]\nsubjectAltName=DNS:`echo ${ARGUMENT_HOSTNAMES} | sed "s/:/,DNS:/g"`")) \
-new -sha256 -key "${CONFIDENTIAL}" -out "${REQUESTFILE}" -outform der -reqexts SAN -subj "/"

#===============================================================================
# Checking if Certificate-Signing-Request (CSR) was successfully created
#===============================================================================
if [ $? != 0 ]; then
	echo "$0: Certificate-Signing-Request (CSR) could not be created!" >&2
	exit 1
fi

#===============================================================================
# Execute defined command BEFORE the ACME challenge is started
#===============================================================================
[ ! -z "${LETSENCRYPT_COMMAND_BEFORE}" ] && eval $LETSENCRYPT_COMMAND_BEFORE

#===============================================================================
# Execute Let's Encrypt and accomplish the ACME challenge to get the certificate
#===============================================================================
certbot certonly --authenticator standalone --server "${LETSENCRYPT_ENDPOINT}" --csr "${REQUESTFILE}" \
--cert-path "${CERTIFICATE_ONLY}.$$" --fullchain-path "${CERTIFICATE_FULL}.$$" --chain-path "${INTERMEDIATE}.$$"

#===============================================================================
# Checking if Certbot has successfully accomplished the ACME challenge
#===============================================================================
if [ $? != 0 ]; then
	echo "$0: Certbot could not successfully accomplish the ACME challenge." >&2
	exit 1
fi

#===============================================================================
# Replace previous certificates with the new obtained certificate files
#===============================================================================
[ -f "${INTERMEDIATE}.$$" ]     && mv "${INTERMEDIATE}.$$"     "${INTERMEDIATE}"
[ -f "${CERTIFICATE_ONLY}.$$" ] && mv "${CERTIFICATE_ONLY}.$$" "${CERTIFICATE_ONLY}"
[ -f "${CERTIFICATE_FULL}.$$" ] && mv "${CERTIFICATE_FULL}.$$" "${CERTIFICATE_FULL}"

#===============================================================================
# Adjust the UNIX permissions with owner and group for the new created files
#===============================================================================
chmod --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"
chown --reference "${CONFIDENTIAL}" "${INTERMEDIATE}" "${CERTIFICATE_ONLY}" "${CERTIFICATE_FULL}"

#===============================================================================
# Execute defined command AFTER the ACME challenge is completed
#===============================================================================
[ ! -z "${LETSENCRYPT_COMMAND_AFTER}" ] && eval $LETSENCRYPT_COMMAND_AFTER