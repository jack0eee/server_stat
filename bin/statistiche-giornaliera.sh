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
#|   |     \                                                                                   |
#|   |     |                                                                                   |
#|   |     '--- server_stats_YYYYMMDD.log                                                      |
#|   |                                                                                         |
#|   '--- images/                                                                              |
#|         \                                                                                   |
#|         |                                                                                   |
#|         '--- server_stats_YYYYMMDD.svg                                                      |
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
#| OUTPUT_SINTESI_DIR       | Directory in cui scriverà il file di sintesi          |
#| OUTPUT_SINTESI_FILE      | File di sintesi                                       |
#| OUTPUT_STATISTICA_DIR    | Directory in cui scriverà il file di statistica (img) |
#| OUTPUT_STATISTICA_FILE   | File di statistica (img)                              |
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
OUTPUT_SINTESI_FILE="$OUTPUT_SINTESI_DIR/server_stats_${DATE}.log"
OUTPUT_STATISTICA_FILE="$OUTPUT_STATISTICA_DIR/server_stats_${DATE}.svg"

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
echo "OUTPUT_SINTESI_DIR       : $OUTPUT_SINTESI_DIR"
echo "OUTPUT_SINTESI_FILE      : $OUTPUT_SINTESI_FILE"
echo "OUTPUT_STATISTICA_DIR    : $OUTPUT_STATISTICA_DIR"
echo "OUTPUT_STATISTICA_FILE   : $OUTPUT_STATISTICA_FILE"
echo


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                          Verifica Parametri                          |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'

#.------------------------------------------------------------.
#| Verifica OUTPUT_SINTESI_FILE | che esista il file          |
#'------------------------------------------------------------'
if [ ! -f "$OUTPUT_SINTESI_FILE" ]; then
   echo "[err] il file $OUTPUT_SINTESI_FILE non esiste."
   echo
   exit 1
fi
echo "[ok] file $OUTPUT_SINTESI_FILE esistente."

#.------------------------------------------------------------.
#| Verifica OUTPUT_STATISTICA_DIR | che esista la directory   |
#'------------------------------------------------------------'
if [ ! -d "$OUTPUT_STATISTICA_DIR" ]; then
    if ! mkdir -p "$OUTPUT_STATISTICA_DIR"; then
        echo "[err] la directory $OUTPUT_STATISTICA_DIR non esiste, e non è possibile crearla."
        echo
        exit 1
    fi
fi
echo "[ok] directory $OUTPUT_STATISTICA_DIR esistente."


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                             Crea Immagine                            |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'
FILE_REGOLA_STATISTICA_MODELLO=$BASE_DIR/lib/statistica-giornaliera.plt.modello
FILE_REGOLA_STATISTICA=$BASE_DIR/tmp/statistica-giornaliera.plt

#.-------------------------------.
#| Customizza lo script GNUPlot  |
#'-------------------------------'
sed \
    -e "s|###IMMAGINE###|$OUTPUT_STATISTICA_FILE|g" \
    -e "s|###FONTE###|$OUTPUT_SINTESI_FILE|g" \
    $FILE_REGOLA_STATISTICA_MODELLO > $FILE_REGOLA_STATISTICA 

if [ ! -f "$FILE_REGOLA_STATISTICA" ]; then
   echo "[err] il file $FILE_REGOLA_STATISTICA non è stato creato."
   echo
   exit 0
fi

echo "[ok] file $FILE_REGOLA_STATISTICA creato."

#.------------------------------------------.
#| Crea Immagine dalla Sintesi per Giornata |
#'------------------------------------------'
$homeInstallGnuPlot/bin/gnuplot $FILE_REGOLA_STATISTICA 

if [ ! -f "$OUTPUT_STATISTICA_FILE" ]; then
   echo "[err] il file $OUTPUT_STATISTICA_FILE non è stato creato."
   echo
   exit 0
fi

rm $FILE_REGOLA_STATISTICA 

echo "[ok] file $OUTPUT_STATISTICA_FILE creato."

#.---------------------------------------------------------------------.
#'---------------------------------------------------------------------'

echo "Operazione riuscita."
echo

exit 0

