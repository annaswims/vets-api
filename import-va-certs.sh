#!/bin/sh

(
    cd /usr/local/share/ca-certificates/
    
    wget \
        --level=1 \
        --quiet \
        --recursive \
        --no-parent \
        --no-host-directories \
        --no-directories \
        --accept="VA*.cer" \
        http://aia.pki.va.gov/PKI/AIA/VA/

    for cert in VA-*.cer
    do
        if file "${cert}" | grep 'PEM'
        then
            cp "${cert}" "${cert}.pem"
        else
            openssl x509 -in "${cert}" -inform der -outform pem -out "${cert}.pem"
        fi
        rm "${cert}"
        cat "${cert}.pem" >> ca-bundle.pem
    done

    update-ca-certificates
)