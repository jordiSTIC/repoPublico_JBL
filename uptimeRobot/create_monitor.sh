#!/bin/bash
source ../common/SticConnect.sh

function showhelp() {
    echo
    echo "Ayuda del script"
    echo "------------------"
    echo "-h --help                               Muestra esta ayuda"
    echo "-i --instances                          Pattern grep para filtrar la lista de instancias en que se crearan monitores si no existen"
    echo "-y --yes                                No pide mensaje de confirmación. (para integrar en script)"
    echo
    exit 0
}

while [ $# -ne 0 ]; do
    case "$1" in
    -h | --help)
        # No hacemos nada más, porque showhelp se saldrá del programa
        showhelp
        ;;
    -i | --instances)
        INSTANCES="$2"
        shift
        ;;

    -y | --yes)
        YES=1
        ;;
    *)
        echo "Argumento no válido"
        showhelp
        ;;
    esac
    shift
done

FILTER=$1
QUERY="select concat_ws(':',name,server) from stic_instances where update_include=1 AND active=1 AND deleted=0 order by name, server"
RES=$(runSticQuery "$QUERY" | grep -E "$INSTANCES")

if [[ -z "${INSTANCES}" ]]; then
    echo "Es necesario seleccionar la(s) instancias"
    showhelp
    exit 0
fi

if [[ -z "${YES}" ]]; then

    NUM_DOMINIOS=$(echo $RES | wc -w)

    echo "$RES"

    echo -------------------------------------

    echo -e "Se va a intentar crear monitores para \e[44m $NUM_DOMINIOS \e[49m subdominios. (Se crearán si no existen)"

    echo -------------------------------------

    confirma=
    while [ -z $confirma ]; do
        echo
        echo -n "¿Continuar? (y/n)? "
        read confirma
    done

    if [ ! $confirma = "y" ]; then
        echo Cancelado.
        exit 0
    fi
fi

COUNTER=1

for INSTANCE in $RES; do
    DOMAIN=$(echo "$INSTANCE" | cut -d\: -f1)
    NAME=$(echo $DOMAIN | cut -d'.' -f 1)
    SERVER=$(echo "$INSTANCE" | cut -d\: -f2)
    echo "$NAME"

    MONITOR_API_STRING="curl -X POST -H 'Cache-Control: no-cache' -H 'Content-Type: application/x-www-form-urlencoded' -d 'interval=60&api_key=u819663-3e5dccf7d041d0b5d1c3d48f&format=json&type=2&url=https://$DOMAIN/SticMonitor.php?token=sinergiaticmon&friendly_name=$NAME $SERVER SticMonitor&keyword_type=2&keyword_value=SticMonitorOk&alert_contacts=2895978' 'https://api.uptimerobot.com/v2/newMonitor'"
    eval "$MONITOR_API_STRING"
    echo
    echo "-----------------------------------"
done
