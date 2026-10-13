#!/bin/bash

#.---------------------------------------------------------------------------------------------.
#| server_stats.sh | Monitoraggio delle Risorse di un Server GNU/Linux / VM                    |
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
#|         \                                                                                   |
#|         |                                                                                   |
#|         '--- server_stats_YYYYMMDD.log                                                      |
#|                                                                                             |
#| Esecuzione prevista : Consigliata ogni 5 minuti se viene inserito nella crontab             |
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
#| LOG_FS                   | Directory su cui è montato il fs da monitorare        |
#| CPU_INTERVAL             | Intervallo per il calcolo della CPU                   |
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


#.---------------------------------------.
#| Verifica Hostname | che sia impostato |
#'---------------------------------------'
if [ -z "$HOSTNAME" ]; then
    exit 1
fi

#.-----------------------------------------------------------------------------------.
#| Verifica LOG_FS | che esista la directory su cui è montato il fs da monitorare.   |
#'-----------------------------------------------------------------------------------'
if [ ! -d "$LOG_FS" ]; then
    exit 1
fi

#.------------------------------------------------------------.
#| Verifica OUTPUT_RILEVAZIONE_DIR | che esista la directory  |
#'------------------------------------------------------------'
if [ ! -d "$OUTPUT_RILEVAZIONE_DIR" ]; then
    if ! mkdir -p "$OUTPUT_RILEVAZIONE_DIR"; then
        exit 1
    fi
fi

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
echo "HOSTNAME     : $HOSTNAME"
echo "DATE         : $DATE"
echo "TIMESTAMP    : $TIMESTAMP"
echo "SCRIPT_DIR   : $SCRIPT_DIR"
echo "BASE_DIR     : $BASE_DIR"
echo "OUTPUT_RILEVAZIONE_DIR   : $OUTPUT_RILEVAZIONE_DIR"
echo "OUTPUT_RILEVAZIONE_FILE  : $OUTPUT_RILEVAZIONE_FILE"
echo "LOG_FS       : $LOG_FS"
echo "CPU_INTERVAL : $CPU_INTERVAL"
echo


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                   Lettura Informazioni dal Server                    |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'

#.------------------------------------------------------------.
#| CPU                                                        |
#'------------------------------------------------------------'
read_cpu_stats()
{
    awk '
        /^cpu / {
            print $2, $3, $4, $5, $6, $7, $8, $9
            exit
        }
    ' /proc/stat
}

CPU1=$(read_cpu_stats)

if [ -z "$CPU1" ]; then
    exit 1
fi

read -r user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 \
    <<< "$CPU1"

sleep "$CPU_INTERVAL"

CPU2=$(read_cpu_stats)

if [ -z "$CPU2" ]; then
    exit 1
fi

read -r user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 \
    <<< "$CPU2"

TOTAL1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
TOTAL2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))

TOTAL_DELTA=$((TOTAL2 - TOTAL1))
IDLE_DELTA=$((idle2 - idle1))
STEAL_DELTA=$((steal2 - steal1))

if [ "$TOTAL_DELTA" -le 0 ]; then
    exit 1
fi

CPU_PCT=$(awk \
    -v total="$TOTAL_DELTA" \
    -v idle="$IDLE_DELTA" \
    'BEGIN {
        printf "%.2f", (total-idle)*100/total
    }')

CPU_STEAL_PCT=$(awk \
    -v total="$TOTAL_DELTA" \
    -v steal="$STEAL_DELTA" \
    'BEGIN {
        printf "%.2f", steal*100/total
    }')


#.------------------------------------------------------------.
#| Load Average                                               |
#'------------------------------------------------------------'
read -r LOAD1 LOAD5 LOAD15 _ < /proc/loadavg


#.------------------------------------------------------------.
#| Ram / Swap (con verifica rilevamento)                      |
#'------------------------------------------------------------'
MEM_TOTAL=$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)
MEM_FREE=$(awk '/^MemFree:/ {print $2; exit}' /proc/meminfo)
MEM_BUFFERS=$(awk '/^Buffers:/ {print $2; exit}' /proc/meminfo)
MEM_CACHED=$(awk '/^Cached:/ {print $2; exit}' /proc/meminfo)

SWAP_TOTAL=$(awk '/^SwapTotal:/ {print $2; exit}' /proc/meminfo)
SWAP_FREE=$(awk '/^SwapFree:/ {print $2; exit}' /proc/meminfo)

if [ -z "$MEM_TOTAL" ] || [ "$MEM_TOTAL" -le 0 ]; then
    exit 1
fi

if [ -z "$MEM_FREE" ] || \
   [ -z "$MEM_BUFFERS" ] || \
   [ -z "$MEM_CACHED" ]; then
    exit 1
fi


#.------------------------------------------------------------.
#| Memoria disponibile / Usata.                               |
#+------------------------------------------------------------+
#| Compatibilità con kernel che non espongono MemAvailable.   |
#|                                                            |
#| La memoria disponibile viene stimata comei :               |
#|                                                            |
#|                MemFree + Buffers + Cached                  |
#|                                                            |
#| perchè il kernel in caso di necessità la Buffers e Cached  |
#| la libera in poco tempo. Questo è tutto da verificare, al  |
#| momento, quindi forse sarebbe piu' corretto non            |
#| considerarla.                                              |
#|                                                            |
#| /proc/meminfo fornisce i valori in kbyte                   |
#|                                                            |
#'------------------------------------------------------------'
MEM_AVAILABLE=$((MEM_FREE + MEM_BUFFERS + MEM_CACHED))
RAM_USED=$((MEM_TOTAL - MEM_AVAILABLE))

RAM_PCT=$(awk \
    -v total="$MEM_TOTAL" \
    -v used="$RAM_USED" \
    'BEGIN {
        printf "%.2f", used*100/total
    }')

RAM_AVAILABLE_BYTES=$((MEM_AVAILABLE * 1024))


#.------------------------------------------------------------.
#| Swap.                                                      |
#'------------------------------------------------------------'
if [ -z "$SWAP_TOTAL" ]; then
    SWAP_TOTAL=0
fi

if [ -z "$SWAP_FREE" ]; then
    SWAP_FREE=0
fi

if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
    SWAP_PCT=$(awk \
        -v total="$SWAP_TOTAL" \
        -v used="$SWAP_USED" \
        'BEGIN {
            printf "%.2f", used*100/total
        }')
else
    SWAP_PCT="0.00"
fi

SWAP_AVAILABLE_BYTES=$((SWAP_FREE * 1024))


#.-------------------------------------------------------------------.
#|                                                                   |
#|                        Filesystem dei log                         |
#|                                                                   |
#'-------------------------------------------------------------------'

#.------------------------------------------------------------.
#| Dimensione del fs                                          |
#'------------------------------------------------------------'
DF_DATA=$(df -P "$LOG_FS" 2>/dev/null | tail -n 1)
if [ -z "$DF_DATA" ]; then
    exit 1
fi

read -r FS_DEVICE FS_SIZE FS_USED FS_AVAILABLE FS_PCT FS_MOUNT \
    <<< "$DF_DATA"

if [ -z "$FS_AVAILABLE" ] || [ -z "$FS_PCT" ]; then
    exit 1
fi

# Rimuove il %
FS_PCT="${FS_PCT%\%}"

# df utilizza blocchi da 1024 byte
FS_AVAILABLE_BYTES=$((FS_AVAILABLE * 1024))


#.------------------------------------------------------------.
#| Occupazione del fs (Dimensione dei file di log)            |
#'------------------------------------------------------------'
LOGS_SIZE_KB=$(du -sk "$LOG_FS" 2>/dev/null | awk '{print $1; exit}')

if [ -z "$LOGS_SIZE_KB" ]; then
    exit 1
fi

LOGS_SIZE_BYTES=$((LOGS_SIZE_KB * 1024))


#.------------------------------------------------------------.
#| Numero di file presenti nel fs.                            |
#'------------------------------------------------------------'
LOGS_FILE_COUNT=$(find "$LOG_FS" -type f 2>/dev/null | wc -l)
LOGS_FILE_COUNT=$(echo "$LOGS_FILE_COUNT" | awk '{print $1}')

if [ -z "$LOGS_FILE_COUNT" ]; then
    LOGS_FILE_COUNT=0
fi


#.-------------------------------------------------------------------.
#|                                                                   |
#|                                                                   |
#|           Scrive nel file di Output la misurazione                |
#|                                                                   |
#|                                                                   |
#'-------------------------------------------------------------------'

#.------------------------------------------------------------.
#| Scrive l'header.                                           |
#'------------------------------------------------------------'
HEADER="#timestamp|hostname|cpu_pct|cpu_steal_pct|load1|load5|load15|ram_used_pct|ram_available_bytes|swap_pct|swap_available_bytes|fs_pct|fs_available_bytes|logs_size_bytes|logs_file_count"

if [ ! -s "$OUTPUT_RILEVAZIONE_FILE" ]; then
   if ! echo "$HEADER" >> "$OUTPUT_RILEVAZIONE_FILE"; then
        exit 1
   fi
fi

#.------------------------------------------------------------.
#| Scrittura Misurazione                                      |
#'------------------------------------------------------------'
DATA="${TIMESTAMP}|${HOSTNAME}|${CPU_PCT}|${CPU_STEAL_PCT}|${LOAD1}|${LOAD5}|${LOAD15}|${RAM_PCT}|${RAM_AVAILABLE_BYTES}|${SWAP_PCT}|${SWAP_AVAILABLE_BYTES}|${FS_PCT}|${FS_AVAILABLE_BYTES}|${LOGS_SIZE_BYTES}|${LOGS_FILE_COUNT}"

if ! echo "$DATA" >> "$OUTPUT_RILEVAZIONE_FILE"; then
   exit 1
fi


#.----------------------------------------------------------------------.
#|                                                                      |
#|                                                                      |
#|                 Visualizzazione della Rilevazione.                   |
#|                                                                      |
#|                                                                      |
#'----------------------------------------------------------------------'
echo
echo ".-------------."
echo "| Misurazioni |"
echo "'-------------'"
echo "TIMESTAMP             : ${TIMESTAMP}"
echo "HOSTNAME              : ${HOSTNAME}"
echo "CPU_PCT               : ${CPU_PCT}"
echo "CPU_STEAL_PCT         : ${CPU_STEAL_PCT}"
echo "LOAD1                 : ${LOAD1}"
echo "LOAD5                 : ${LOAD5}"
echo "LOAD15                : ${LOAD15}"
echo "RAM_PCT               : ${RAM_PCT}"
echo "RAM_AVAILABLE_BYTES   : ${RAM_AVAILABLE_BYTES}"
echo "SWAP_PCT              : ${SWAP_PCT}"
echo "SWAP_AVAILABLE_BYTES  : ${SWAP_AVAILABLE_BYTES}"
echo "FS_PCT                : ${FS_PCT}"
echo "FS_AVAILABLE_BYTES    : ${FS_AVAILABLE_BYTES}"
echo "LOGS_SIZE_BYTES       : ${LOGS_SIZE_BYTES}"
echo "LOGS_FILE_COUNT       : ${LOGS_FILE_COUNT}"

echo
echo ".--------------------------------------------."
echo "| Misurazioni Tracciate nel file giornaliero |"
echo "'--------------------------------------------'"
echo "HEADER                : ${HEADER}"
echo "DATA                  : ${DATA}"
echo

exit 0

#===--- EOF


