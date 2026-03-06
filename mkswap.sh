#!/bin/bash

# Script untuk membuat swap file di Linux
# Perlu dijalankan dengan root privileges

# Cek apakah dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Script ini harus dijalankan dengan sudo"
    echo "Gunakan: sudo ./mkswap.sh"
    exit 1
fi

# Tampilkan menu
echo "=================================="
echo "    Pembuat Swap File"
echo "=================================="
echo "Pilih ukuran swap yang ingin dibuat:"
echo "1. 2 GB"
echo "2. 4 GB"
echo "3. Custom (input sendiri)"
echo "4. Keluar"
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
            echo "Error: Input tidak valid. Masukkan angka positif."
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
        echo "Error: Pilihan tidak valid"
        exit 1
        ;;
esac

SWAP_FILE="/swapfile"

echo ""
echo "=================================="
echo "Konfigurasi Swap:"
echo "Ukuran: $SWAP_SIZE ($SWAP_SIZE_GB GB)"
echo "Lokasi: $SWAP_FILE"
echo "=================================="

# Cek apakah swap file sudah ada
if [ -f "$SWAP_FILE" ]; then
    echo "Peringatan: $SWAP_FILE sudah ada!"
    read -p "Hapus dan buat ulang? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        swapoff "$SWAP_FILE" 2>/dev/null
        rm -f "$SWAP_FILE"
        echo "File swap lama dihapus."
    else
        echo "Dibatalkan."
        exit 0
    fi
fi

echo ""
echo "[1/7] Membuat swap file $SWAP_SIZE..."
fallocate -l "$SWAP_SIZE" "$SWAP_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Gagal membuat swap file dengan fallocate."
    echo "Mencoba alternatif dengan dd..."
    dd if=/dev/zero of="$SWAP_FILE" bs=1G count="$SWAP_SIZE_GB" status=progress
    if [ $? -ne 0 ]; then
        echo "Error: Gagal membuat swap file."
        exit 1
    fi
fi

echo "[2/7] Mengatur permission swap file..."
chmod 600 "$SWAP_FILE"

echo "[3/7] Memformat swap file..."
mkswap "$SWAP_FILE"

echo "[4/7] Mengaktifkan swap..."
swapon "$SWAP_FILE"

echo ""
echo "[5/7] Status memori:"
free -h

echo ""
echo "[6/7] Informasi swap:"
swapon --show

echo ""
echo "[7/7] Backup dan konfigurasi fstab untuk persisten..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    cp /etc/fstab /etc/fstab.bak
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    echo "Entry ditambahkan ke /etc/fstab"
    echo "Backup dibuat di /etc/fstab.bak"
else
    echo "Entry swap sudah ada di /etc/fstab"
fi

echo ""
echo "=================================="
echo "    Swap Berhasil Dibuat!"
echo "=================================="
echo "Ukuran: $SWAP_SIZE"
echo "Lokasi: $SWAP_FILE"
echo ""
echo "Swap akan tetap aktif setelah reboot."
echo "=================================="
