#!/bin/bash

# Warna
R=$'\033[0;31m'
G=$'\033[0;32m'
Y=$'\033[0;33m'
B=$'\033[0;34m'
M=$'\033[0;35m'
C=$'\033[0;36m'
W=$'\033[0;37m'
BR=$'\033[1;91m'
BG=$'\033[1;92m'
BY=$'\033[1;93m'
BB=$'\033[1;94m'
BM=$'\033[1;95m'
BC=$'\033[1;96m'
BW=$'\033[1;97m'
N=$'\033[0m'

# Animated success message
show_success() {
    printf "\r${G}[OK]${N} $1\n"
}

# Animated processing
animate_step() {
    local step=$1
    local total=$2
    local msg=$3
    local command=$4

    printf "${C}[$step/$total]${N} $msg..."
    eval "$command" > /dev/null 2>&1
    sleep 0.3
    show_success "Selesai"
}

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo "${R}Error: Script ini harus dijalankan dengan sudo${N}"
    echo "Gunakan: sudo ./mkswap.sh"
    exit 1
fi

clear

# Banner
printf "${BC}"
cat << "EOF"
==================================
    Pembuat Swap File
==================================
EOF
printf "${N}"

echo "Pilih ukuran swap yang ingin dibuat:"
echo "${BY}1.${N} 2 GB"
echo "${BY}2.${N} 4 GB"
echo "${BY}3.${N} Custom (input sendiri)"
echo "${BY}4.${N} Keluar"
echo "=================================="
read -p "Masukkan pilihan (1-4): " choice

case $choice in
    1)
        SWAP_SIZE="2G"
        SWAP_SIZE_GB=2
        ;;
    2)
        SWAP_SIZE="4G"
        SWAP_SIZE_GB=4
        ;;
    3)
        read -p "Masukkan ukuran swap dalam GB (contoh: 8): " custom_size
        if [[ ! "$custom_size" =~ ^[0-9]+$ ]] || [ "$custom_size" -lt 1 ]; then
            echo "${R}Error: Input tidak valid. Masukkan angka positif.${N}"
            exit 1
        fi
        SWAP_SIZE="${custom_size}G"
        SWAP_SIZE_GB=$custom_size
        ;;
    4)
        echo "Keluar..."
        exit 0
        ;;
    *)
        echo "${R}Error: Pilihan tidak valid${N}"
        exit 1
        ;;
esac

SWAP_FILE="/swapfile"

echo ""
echo "=================================="
printf "${BC}Konfigurasi Swap:${N}\n"
printf "Ukuran: ${BY}%s${N} (%s GB)\n" "$SWAP_SIZE" "$SWAP_SIZE_GB"
printf "Lokasi: ${BY}%s${N}\n" "$SWAP_FILE"
echo "=================================="

# Cek file exist
if [ -f "$SWAP_FILE" ]; then
    echo ""
    echo "${Y}Peringatan: $SWAP_FILE sudah ada!${N}"
    read -p "Hapus dan buat ulang? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        printf "Menghapus swap lama..."
        swapoff "$SWAP_FILE" 2>/dev/null
        rm -f "$SWAP_FILE"
        sleep 0.5
        show_success "File swap lama dihapus"
    else
        echo "${Y}Dibatalkan.${N}"
        exit 0
    fi
fi

echo ""
printf "${BC}==================================${N}\n"
printf "${BC}    Memulai Proses...${N}\n"
printf "${BC}==================================${N}\n"
echo ""

# Step 1
animate_step 1 7 "Membuat swap file $SWAP_SIZE" "fallocate -l $SWAP_SIZE $SWAP_FILE"

# Step 2
animate_step 2 7 "Mengatur permission" "chmod 600 $SWAP_FILE"

# Step 3
printf "${C}[3/7]${N} Memformat swap file..."
mkswap "$SWAP_FILE" > /dev/null 2>&1
sleep 0.4
show_success "Selesai"

# Step 4
printf "${C}[4/7]${N} Mengaktifkan swap..."
swapon "$SWAP_FILE" 2>/dev/null
sleep 0.3
show_success "Selesai"

# Step 5
echo ""
printf "${C}[5/7]${N} Status memori:\n"
free -h | while read line; do
    printf "  ${W}%s${N}\n" "$line"
done
sleep 0.5

# Step 6
echo ""
printf "${C}[6/7]${N} Informasi swap:\n"
swapon --show | while read line; do
    printf "  ${W}%s${N}\n" "$line"
done
sleep 0.5

# Step 7
echo ""
if ! grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null; then
    printf "${C}[7/7]${N} Konfigurasi persisten (fstab)..."
    cp /etc/fstab /etc/fstab.bak 2>/dev/null
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab 2>/dev/null
    sleep 0.4
    show_success "Entry ditambahkan"
    printf "  ${W}Backup: /etc/fstab.bak${N}\n"
else
    printf "${C}[7/7]${N} Entry swap sudah ada di fstab\n"
fi

echo ""
printf "${BC}==================================${N}\n"
printf "${BG}    Swap Berhasil Dibuat!${N}\n"
printf "${BC}==================================${N}\n"
printf "Ukuran: ${BY}%s${N}\n" "$SWAP_SIZE"
printf "Lokasi: ${BY}%s${N}\n" "$SWAP_FILE"
echo ""
printf "${W}Swap akan tetap aktif setelah reboot.${N}\n"
printf "${BC}==================================${N}\n"
echo ""
