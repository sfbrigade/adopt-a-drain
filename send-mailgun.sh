set -o allexport
source ./.env
set +o allexport

./swaks --auth \
        --server $MAILSERVER_HOST \
        --au $MAILSERVER_USERNAME \
        --ap $MAILSERVER_PASSWORD \
        --port 587 \
        -tls \
        --from postmaster@mail.mysticdrains.org \
        --to me@alexjball.com \
        --h-Subject: "Hello" \
        --body 'Testing some Mailgun awesomness!'
