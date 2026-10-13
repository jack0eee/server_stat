#!/bin/bash

#.---------------------------------------------------------------------------------------------.
#| sintesi.sh | Monitoraggio delle Risorse di un Server GNU/Linux / VM                         |
#+---------------------------------------------------------------------------------------------+
#|                                                                                             |
#| Struttura prevista :                                                                        |
#|                                                                                             |
#|   server_stats <DIR>                                                                        |
#|   |                                                                                         |
#|   +--- bin <DIR>                                                                            |
#|   |     \                                                                                   |
#|   |     |                                                                                   |
#|   │     '--- server_stats.sh                                                                |
#|   |                                                                                         |
#|   '--- logs/                                                                                |
#|   |     \                                                                                   |
#|   |     |                                                                                   |
#|   |     '--- server_stats_YYYYMMDD.log                                                      |
#|   |                                                                                         |
#|   '--- logs.sintesi /                                                                       |
#|         \                                                                                   |
#|         |                                                                                   |
#|         '--- server_stats_YYYYMMDD.log                                                      |
#|                                                                                             |
#|                                                                                             |
#| Struttura del file delle rilevazioni giornaliere (server_stats_YYYYMMDD.log) :              |
#|                                                                                             |
#| timestamp                 | Timestamp della rilevazione nel formato YYYYMMDD HHMMSS         |
#| hostname                  | Hostname della macchina                                         |
#| cpu_pct                   |                                                                 |
#| cpu_steal_pct             |                                                                 |
#| load1                     |                                                                 |
#| load5                     |                                                                 |
#| load15                    |                                                                 |
#| ram_used_pct              | RAM Usata                                                       |
#| ram_available_bytes       | RAM Disponibile (byte)                                          |
#| swap_pct                  | SWAP Usata                                                      |
#| swap_available_bytes      | SWAP Disponibile (byte)                                         |
#| fs_pct                    | Filesystem dei LOG Applicativi : spazio occupato (percentuale)  |
#| fs_available_bytes        | Filesystem dei LOG Applicativi : spazio disponibile (byte)      |
#| logs_size_bytes           | Filesystem dei LOG Applicativi : spazio occupato (byte)         |
#| logs_file_count           | Filesystem dei LOG Applicativi : numero di file                 |
#|                                                                                             |
#| ---------------                                                                             |
#|                                                                                             |
#| 2026 (c) Angelo Raffaele Granito  -- v1        Distribuito sotto licenza GNU GPL v3         |
#|                                                                                             |
#'---------------------------------------------------------------------------------------------'

set -u

#.----------------------------------------------------------------------------------.
#|                                                                                  |
#|                                                                                  |
#|                              Impostazione Parametri                              |
#|                                                                                  |
#| HOSTNAME                 | Hostname Breve associato al server.                   |
#| DATE                     | Data di sistema nel formato YYYYMMDD                  |
#| TIMESTAMP                | Timestamp di sistema nel formato impostato.           |
#| SCRIPT_DIR               | Directory in cui si trova questo script.              |
#| BASE_DIR                 | Directory principale HOME/bin/this -> HOME            |
#| OUTPUT_RILEVAZIONE_DIR   | Directory in cui scriverà il file di rilevazione      |
#| OUTPUT_RILEVAZIONE_FILE  | File di rilevazione rilevazione                       |
#| OUTPUT_SINTESI_DIR       | Directory in cui scriverà il file di sintesi          |
#| OUTPUT_SINTESI_FILE      | File di sintesi                                       |
#|                                                                                  |
#'----------------------------------------------------------------------------------'
HOSTNAME=$(hostname -s 2>/dev/null)
DATE=$(date '+%Y%m%d')
TIMESTAMP=$(date '+%Y%m%d %H%M%S')
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
#.----------------------------------------.
#| Include Conf User                      |
#'----------------------------------------'
. $BASE_DIR/conf/server_stats.conf
#.----------------------------------------.
#'----------------------------------------'
OUTPUT_RILEVAZIONE_FILE="$OUTPUT_RILEVAZIONE_DIR/server_stats_${DATE}.log"
OUTPUT_SINTESI_FILE="$OUTPUT_SINTESI_DIR/server_stats_${DATE}.log"


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                        Visualizzazione Banner                        |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'
echo "running..."
echo
echo "server_stats v.01 -- jack0e"
echo

#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|               Visualizzazione dei Parametri Impostati.               |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'
echo ".------------."
echo "| Parametri  |"
echo "'------------'"
echo "HOSTNAME                 : $HOSTNAME"
echo "DATE                     : $DATE"
echo "TIMESTAMP                : $TIMESTAMP"
echo "SCRIPT_DIR               : $SCRIPT_DIR"
echo "BASE_DIR                 : $BASE_DIR"
echo "OUTPUT_RILEVAZIONE_DIR   : $OUTPUT_RILEVAZIONE_DIR"
echo "OUTPUT_RILEVAZIONE_FILE  : $OUTPUT_RILEVAZIONE_FILE"
echo "OUTPUT_SINTESI_DIR       : $OUTPUT_SINTESI_DIR"
echo "OUTPUT_SINTESI_FILE      : $OUTPUT_SINTESI_FILE"
echo


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                          Verifica Parametri                          |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'

#.------------------------------------------------------------.
#| Verifica OUTPUT_RILEVAZIONE_FILE | che esista il file      |
#'------------------------------------------------------------'
if [ ! -f "$OUTPUT_RILEVAZIONE_FILE" ]; then
   echo "[err] il file $OUTPUT_RILEVAZIONE_FILE non esiste."
   echo
   exit 1
fi
echo "[ok] file $OUTPUT_RILEVAZIONE_FILE esistente."

#.------------------------------------------------------------.
#| Verifica OUTPUT_SINTESI_DIR | che esista la directory      |
#'------------------------------------------------------------'
if [ ! -d "$OUTPUT_SINTESI_DIR" ]; then
    if ! mkdir -p "$OUTPUT_SINTESI_DIR"; then
        echo "[err] la directory $OUTPUT_SINTESI_DIR non esiste, e non è possibile crearla."
        echo
        exit 1
    fi
fi
echo "[ok] directory $OUTPUT_SINTESI_DIR esistente."


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                             Crea Sintesi                             |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'
FILE_REGOLA_SINTESI=$BASE_DIR/lib/sintesi-giornaliera.swk

#.------------------------------------------------------------.
#| Verifica FILE_REGOLA_SINTESI | che esista il file      |
#'------------------------------------------------------------'
if [ ! -f "$FILE_REGOLA_SINTESI" ]; then
   echo "[err] il file $FILE_REGOLA_SINTESI non esiste."
   echo
   exit 1
fi
echo "[ok] file $FILE_REGOLA_SINTESI esistente."

#.-----------------------------------------------------------.
#| Crea Sintesi : una riga per ogni ora prendendo i valori   |
#| di picco della giornata.                                  |
#'-----------------------------------------------------------'
awk \
-f $FILE_REGOLA_SINTESI \
$OUTPUT_RILEVAZIONE_FILE > $OUTPUT_SINTESI_FILE 

if [ ! -f $OUTPUT_SINTESI_FILE ]; then
   echo "[err] il file $OUTPUT_SINTESI_FILE non creato."
   echo
   exit 0
fi

echo "[ok] file $OUTPUT_SINTESI_FILE creato."

#.------------------------------------------------------------------------------------------------.
#'------------------------------------------------------------------------------------------------'

echo "Operazione riuscita."
echo

exit 0

# ===--- EOF
