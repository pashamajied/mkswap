#!/bin/bash

# Script untuk membuat swap file di Linux
# Perlu dijalankan dengan root privileges

# Spinner animation
spinner() {
    local pid=$1
    local msg=$2
    local delay=0.1
    local spinstr='|/-\'
    echo -ne "$msg "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Animated success message
show_success() {
    echo -e "\r\033[0;32m[OK]\033[0m $1"
}

# Animated processing with fake delay for effect
animate_step() {
    local step=$1
    local total=$2
    local msg=$3
    local command=$4
    local show_output=$5

    echo -ne "\033[0;36m[$step/$total]\033[0m $msg..."

    # Run command
    if [ "$show_output" = "yes" ]; then
        echo ""
        eval "$command"
        show_success "Selesai"
    else
        eval "$command" > /dev/null 2>&1
        # Small delay for animation effect
        sleep 0.3
        show_success "Selesai"
    fi
}

# Cek apakah dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[0;31mError: Script ini harus dijalankan dengan sudo\033[0m"
    echo "Gunakan: sudo ./mkswap.sh"
    exit 1
fi

clear

# Animated banner
echo -e "\033[1;36m"
cat << "EOF"
==================================
    Pembuat Swap File
==================================
EOF
echo -e "\033[0m"

echo "Pilih ukuran swap yang ingin dibuat:"
echo -e "\033[1;33m1.\033[0m 2 GB"
echo -e "\033[1;33m2.\033[0m 4 GB"
echo -e "\033[1;33m3.\033[0m Custom (input sendiri)"
echo -e "\033[1;33m4.\033[0m Keluar"
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
            echo -e "\033[0;31mError: Input tidak valid. Masukkan angka positif.\033[0m"
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
        echo -e "\033[0;31mError: Pilihan tidak valid\033[0m"
        exit 1
        ;;
esac

SWAP_FILE="/swapfile"

echo ""
echo "=================================="
echo -e "\033[1;36mKonfigurasi Swap:\033[0m"
echo -e "Ukuran: \033[1;33m$SWAP_SIZE\033[0m ($SWAP_SIZE_GB GB)"
echo -e "Lokasi: \033[1;33m$SWAP_FILE\033[0m"
echo "=================================="

# Cek apakah swap file sudah ada
if [ -f "$SWAP_FILE" ]; then
    echo ""
    echo -e "\033[0;33mPeringatan: $SWAP_FILE sudah ada!\033[0m"
    read -p "Hapus dan buat ulang? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -ne "Menghapus swap lama..."
        swapoff "$SWAP_FILE" 2>/dev/null
        rm -f "$SWAP_FILE"
        sleep 0.5
        show_success "File swap lama dihapus"
    else
        echo -e "\033[0;33mDibatalkan.\033[0m"
        exit 0
    fi
fi

echo ""
echo -e "\033[1;36m==================================\033[0m"
echo -e "\033[1;36m    Memulai Proses...\033[0m"
echo -e "\033[1;36m==================================\033[0m"
echo ""

# Step 1: Membuat swap file
animate_step 1 7 "Membuat swap file $SWAP_SIZE" "fallocate -l $SWAP_SIZE $SWAP_FILE" "no"

# Step 2: Permission
animate_step 2 7 "Mengatur permission" "chmod 600 $SWAP_FILE" "no"

# Step 3: Format swap
echo -ne "\033[0;36m[3/7]\033[0m Memformat swap file..."
mkswap "$SWAP_FILE" > /dev/null 2>&1
sleep 0.4
show_success "Selesai"

# Step 4: Aktifkan swap
echo -ne "\033[0;36m[4/7]\033[0m Mengaktifkan swap..."
swapon "$SWAP_FILE" 2>/dev/null
sleep 0.3
show_success "Selesai"

# Step 5: Status memori
echo ""
echo -e "\033[0;36m[5/7]\033[0m Status memori:"
free -h | while read line; do
    echo -e "  \033[0;37m$line\033[0m"
done
sleep 0.5

# Step 6: Informasi swap
echo ""
echo -e "\033[0;36m[6/7]\033[0m Informasi swap:"
swapon --show | while read line; do
    echo -e "  \033[0;37m$line\033[0m"
done
sleep 0.5

# Step 7: Fstab configuration
echo ""
if ! grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null; then
    echo -ne "\033[0;36m[7/7]\033[0m Konfigurasi persisten (fstab)..."
    cp /etc/fstab /etc/fstab.bak 2>/dev/null
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab 2>/dev/null
    sleep 0.4
    show_success "Entry ditambahkan"
    echo -e "  \033[0;90mBackup: /etc/fstab.bak\033[0m"
else
    echo -e "\033[0;36m[7/7]\033[0m Entry swap sudah ada di fstab"
fi

echo ""
echo -e "\033[1;36m==================================\033[0m"
echo -e "\033[1;32m    Swap Berhasil Dibuat!\033[0m"
echo -e "\033[1;36m==================================\033[0m"
echo -e "Ukuran: \033[1;33m$SWAP_SIZE\033[0m"
echo -e "Lokasi: \033[1;33m$SWAP_FILE\033[0m"
echo ""
echo -e "\033[0;37mSwap akan tetap aktif setelah reboot.\033[0m"
echo -e "\033[1;36m==================================\033[0m"
echo ""
