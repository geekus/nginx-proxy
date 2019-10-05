#!/bin/sh

# Script to generate a self signed certificate in certs dir

CERT_CONF_TEMPLATE="certificate.conf.tmpl"
CERTS_DIR="./certs/"

HOSTNAME=''

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -k|--keychain)
        KEYCHAIN="login"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# Read hostname from first positional argument
if [[ -n "$1" ]]; then
    HOSTNAME="$1"
fi

if [[ -z "$HOSTNAME" ]]; then
    echo "No hostname provided. Exiting."
    exit
elif [[ -n "$HOSTNAME" ]]; then
    echo "$HOSTNAME"
    TMP_TEMPLATE=`mktemp`
    cat $CERT_CONF_TEMPLATE >> $TMP_TEMPLATE
    echo "DNS.1 = $HOSTNAME" >> $TMP_TEMPLATE
    openssl req \
        -config $TMP_TEMPLATE \
        -new \
        -sha256 \
        -newkey rsa:2048 \
        -nodes \
        -keyout $CERTS_DIR$HOSTNAME.key \
        -x509 \
        -days 365 \
        -subj "/C=NO/ST=Oslo/L=Oslo/O=$HOSTNAME/CN=$HOSTNAME" \
        -out $CERTS_DIR$HOSTNAME.crt
    rm $TMP_TEMPLATE
fi

if [[ `uname` == "Darwin" ]]; then
    # TODO: Add options for both system and login keychain
    if [[ -z "$KEYCHAIN" ]]; then
        echo "Add to keychain? Requires sudo."
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    KEYCHAIN='login'; break;;
                No )
                    break;;
            esac
        done
    fi

    if [[ "$KEYCHAIN" == "login" ]]; then
        sudo security add-trusted-cert \
            -d \
            -r trustRoot \
            -k ~/Library/Keychains/login.keychain-db $CERTS_DIR$HOSTNAME.crt;
    fi
fi
